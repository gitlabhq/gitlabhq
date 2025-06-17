# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Commands
      # Metrics related commands that collect various deployment and cluster related metrics
      #
      class Metrics < Command
        desc "start", "Start metrics collector background process"
        long_desc <<~DESC
          Periodically collect and store metrics for pods.
          It starts a background process that collects metrics at regular intervals.
          Metrics are stored in a JSON file in output directory.
        DESC
        option :namespace,
          desc: "Kubernetes namespace",
          default: "gitlab",
          type: :string,
          aliases: "-n"
        option :interval,
          desc: "Interval in seconds between fetching and storing resource metrics values",
          type: :numeric,
          default: 5,
          aliases: "-i"
        option :output_dir,
          desc: "Output dir for metrics json file",
          default: Helpers::Utils.config_dir,
          type: :string,
          aliases: "-o"
        def start
          Kubectl::Metrics::Collector.new(
            namespace: options[:namespace],
            interval: options[:interval],
            output_dir: options[:output_dir]
          ).start
        end

        desc "stop", "Stop metrics collector background process"
        long_desc <<~DESC
          Stop the metrics collector background process.
          This command will stop the background process started by 'start' command.
        DESC
        option :timeout,
          desc: "Timeout to wait for graceful shutdown",
          type: :numeric,
          default: 5,
          aliases: "-t"
        def stop
          log("Stopping metrics collector process", :info, bright: true)
          pid_file = Helpers::Utils.metrics_pid_file
          pid = File.read(pid_file).to_i
          log("PID file '#{pid_file}' is empty", :error) && exit(1) if pid.zero?

          Helpers::Spinner.spin("terminating process #{pid}", raise_on_error: false) do
            Process.kill(Kubectl::Metrics::Collector::SHUTDOWN_SIGNAL, pid)
            terminated = false

            options[:timeout].times do
              Kernel.sleep 1
              begin
                Process.kill(0, pid)
              rescue Errno::ESRCH
                terminated = true
                log("Process #{pid} successfully terminated")
                break
              end
            end
            next if terminated

            Process.kill("KILL", pid)
            log("Process #{pid} didn't respond to TERM signal, used KILL to terminate!", :warn)
          end
        rescue Errno::ENOENT
          log("PID file '#{pid_file}' not found!", :error)
          exit(1)
        end

        desc "serve [OUTPUT_TYPE]", "Visualize metrics graphs from metrics json file"
        long_desc <<~DESC
          Visualize metrics data collected by background process.
          OUTPUT_TYPE: Output type (currently only 'console' is supported).
        DESC
        option :type,
          desc: "Resource type to visualize.",
          default: "cpu",
          type: :string,
          enum: %w[cpu memory],
          aliases: "-t"
        option :metrics_dir,
          desc: "Directory where metrics json file is located",
          default: Helpers::Utils.config_dir,
          type: :string,
          aliases: "-o"
        option :max_width,
          desc: "Max output width for graphs.",
          default: nil,
          type: :numeric
        option :data_points,
          desc: "Last N data points to display.",
          default: nil,
          type: :numeric
        def serve(_output = "console")
          Gitlab::Orchestrator::Metrics::Console.new(
            File.join(options[:metrics_dir], Helpers::Utils::METRICS_FILENAME),
            data_points: options[:data_points],
            max_width: options[:max_width]
          ).generate(options[:type])
        end
      end
    end
  end
end
