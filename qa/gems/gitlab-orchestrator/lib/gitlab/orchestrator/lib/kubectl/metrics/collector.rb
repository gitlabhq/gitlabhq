# frozen_string_literal: true

require "json"
require "fileutils"
require "time"
require "logger"

module Gitlab
  module Orchestrator
    module Kubectl
      module Metrics
        class Collector
          include Helpers::Output

          SHUTDOWN_SIGNAL = "TERM"

          def initialize(namespace:, interval: 5, output_dir: Helpers::Utils.config_dir)
            @namespace = namespace
            @output_dir = output_dir
            @metrics_file = File.join(@output_dir, Helpers::Utils::METRICS_FILENAME)
            @interval = interval
            @metrics_data = {}
            @shutdown_timeout = 10
          end

          def start
            log("Starting metrics collector process", :info, bright: true)
            Helpers::Spinner.spin("running initial setup") { setup }

            run_background_process
          end

          private

          attr_reader :namespace, :output_dir, :metrics_file, :metrics_data, :interval

          # Kubectl client
          #
          # @return [Gitlab::Orchestrator::Kubectl::Client]
          def kubectl
            @kubectl ||= Client.new(namespace)
          end

          def output_file
            @output_file ||= File.join(output_dir, "metrics-collector.log").tap do |file|
              FileUtils.rm_f(file)
            end
          end

          # Logger instance used by background process
          #
          # @return [Logger]
          def logger
            @logger ||= Logger.new(output_file)
          end

          # Run initial setup
          #
          # @return [void]
          def setup
            setup_output_dir
            check_namespace
            setup_signal_handlers
          end

          # Create output directory if it does not exist
          #
          # @return [void]
          def setup_output_dir
            FileUtils.mkdir_p(output_dir)
            log(" Created output directory: #{output_dir}")
          end

          # Check if namespace exists
          #
          # @return [void]
          def check_namespace
            kubectl.get_namespace
          rescue Kubectl::Client::Error
            log(" Namespace '#{namespace}' does not exist", :error)
            exit 1
          end

          # Setup signal handler for graceful shutdown
          #
          # @return [void]
          def setup_signal_handlers
            Signal.trap(SHUTDOWN_SIGNAL) do
              puts "Shutting down metrics collector"

              @shutdown_timeout.times do
                break unless @collection_running

                sleep 1
              end

              FileUtils.rm_f(Helpers::Utils.metrics_pid_file)
              exit
            end
            log(" Added signal handler for graceful shutdown")
          end

          # Daemonize metrics collector process
          #
          # @return [void]
          def run_background_process
            pid = Process.fork

            if pid
              Helpers::Spinner.spin("creating background process") do
                log(" Saved process pid #{pid} to #{Helpers::Utils.metrics_pid_file}")
              end

              exit
            end

            logger.info("Starting metrics collection for all pods in namespace: #{namespace}")
            File.write(Helpers::Utils.metrics_pid_file, Process.pid)

            # Redirect all output to logfile
            $stdout.reopen(output_file, "a")
            $stderr.reopen(output_file, "a")

            run
          end

          # Run metrics collector
          #
          # @return [void]
          def run
            loop do
              begin
                collect_metrics
              rescue StandardError => e
                logger.error("Error during metrics collection: #{e.message}")
              end

              sleep interval
            end
          end

          # Get resource definitions for all containers in given pod
          #
          # @param pod_name [String]
          # @return [Hash]
          def get_pod_resources(pod_name)
            containers = kubectl.pod(pod_name).dig(:spec, :containers) || []

            containers.each_with_object({}) do |container, hsh|
              name = container[:name]
              requests = container.dig(:resources, :requests) || {}
              limits = container.dig(:resources, :limits) || {}

              hsh[name] = {
                requests: { cpu: parse_cpu_limits(requests[:cpu]), memory: parse_memory_limits(requests[:memory]) },
                limits: { cpu: parse_cpu_limits(limits[:cpu]), memory: parse_memory_limits(limits[:memory]) }
              }
            end
          rescue Kubectl::Client::Error => e
            logger.warn("Could not fetch pod spec for #{pod_name}: #{e.message}")
            {}
          end

          # Collect pod resource metrics
          #
          # @return [void]
          def collect_metrics
            @collection_running = true
            timestamp = Time.now.to_i

            logger.info("Collecting metrics...")
            pod_metrics = kubectl.top_pods

            if pod_metrics.empty?
              logger.warn("No pods found in namespace or no metrics available")
              return
            end

            container_count = 0

            pod_metrics.each do |pod_name, containers|
              next if containers.empty?

              containers.each do |container|
                container_name = container[:container]
                full_name = "#{pod_name}/#{container_name}"
                cpu_value = parse_cpu_limits(container[:cpu])
                memory_value = parse_memory_limits(container[:memory])

                # If container is not in the data yet, initialize its structure
                unless metrics_data[full_name]
                  resources = get_pod_resources(pod_name)
                  default_resources = { cpu: 0, memory: 0 }
                  metrics_data[full_name] = {
                    "requests" => resources.dig(container_name, :requests) || default_resources,
                    "limits" => resources.dig(container_name, :limits) || default_resources,
                    "metrics" => []
                  }
                end

                # Add new metric entry
                metric_entry = {
                  "timestamp" => timestamp,
                  "cpu" => cpu_value,
                  "memory" => memory_value
                }
                metrics_data[full_name]["metrics"] << metric_entry
                container_count += 1
              end
            end

            logger.info "Collected metrics for #{container_count} containers"

            save_metrics
          ensure
            @collection_running = false
          end

          # Save metrics file
          #
          # @return [void]
          def save_metrics
            File.write(metrics_file, JSON.pretty_generate(metrics_data))
            logger.info("Saved metrics to #{metrics_file}")
          rescue StandardError => e
            logger.error("Failed to save metrics: #{e.message}")
          end

          # Convert limit value to milicores integer or float
          #
          # @param cpu_limit_str [String]
          # @return [Number]
          def parse_cpu_limits(cpu_limit_str)
            case cpu_limit_str
            when /(\d+)m$/
              ::Regexp.last_match(1).to_i
            when /(\d+)n$/
              (::Regexp.last_match(1).to_f / 1_000_000).round
            when /(\d+\.?\d*)$/
              (::Regexp.last_match(1).to_f * 1000).to_i
            else
              0
            end
          end

          # Convert memory limit value to MiB integer or float
          #
          # @param memory_limit_str [String]
          # @return [Number]
          def parse_memory_limits(memory_limit_str)
            case memory_limit_str
            when /(\d+)Mi$/
              ::Regexp.last_match(1).to_i
            when /(\d+)Ki$/
              (::Regexp.last_match(1).to_f / 1024).round
            when /(\d+)Gi$/
              (::Regexp.last_match(1).to_f * 1024).to_i
            when /(\d+)M$/
              (::Regexp.last_match(1).to_f * 0.953674).round  # MB to MiB conversion
            when /(\d+)G$/
              (::Regexp.last_match(1).to_f * 953.674).round   # GB to MiB conversion
            when /(\d+)$/
              (::Regexp.last_match(1).to_f / 1048576).round   # Bytes to MiB conversion
            else
              0
            end
          end
        end
      end
    end
  end
end
