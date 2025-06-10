# frozen_string_literal: true

require 'json'
require 'time'

module Gitlab
  module Orchestrator
    module Metrics
      class Console
        include Helpers::Output

        DEFAULT_GRAPH_WIDTH = 100
        GRAPH_HEIGHT = 20
        MIN_GRAPH_WIDTH = 40
        MAX_GRAPH_WIDTH = 200

        def initialize(metrics_file, data_points: nil, max_width: nil)
          @metrics_file = metrics_file
          @data_points = data_points || 0
          @max_width = max_width || 0
        end

        # Generate and display graphs for specific metric type
        #
        # @param metric_type [String]
        # @return [void]
        def generate(metric_type)
          if data.empty?
            log("No metrics data found in #{metrics_file}", :warn)
            return
          end

          metric_name = metric_type.upcase
          unit = metric_type == 'cpu' ? "m" : "Mi"
          total_requests = total_resource_allocation("requests", metric_type)
          total_limits = total_resource_allocation("limits", metric_type)

          title = [colorize("#{metric_name} USAGE GRAPHS", :magenta, bright: true)]
          title << colorize("Total Requests: #{total_requests}#{unit}", :magenta, bright: true)
          title << colorize("Total Limits: #{total_limits}#{unit}", :magenta, bright: true)

          log(title.join(" | "))
          log("=" * 60, :info, bright: true)
          log("Generated at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}", :info, bright: true)

          data.each do |container_name, container_data|
            metrics = container_data["metrics"] || []

            if metrics.empty?
              log("\n❌ No metrics available for pod: #{container_name}", :error)
              next
            end

            selected_metrics = data_points != 0 ? metrics.last(data_points) : metrics
            values = selected_metrics.map { |m| { val: m[metric_type], ts: m["timestamp"] } }
            request = container_data["requests"][metric_type].then { |val| val.positive? ? val : nil }
            limit = container_data["limits"][metric_type].then { |val| val.positive? ? val : nil }
            title = "#{metric_name} Usage - Container: #{container_name}"

            generate_ascii_graph(values, title, unit, request, limit)
          end
        end

        private

        attr_reader :metrics_file, :data_points, :max_width

        def data
          @data ||= load_metrics
        end

        # Get total allocation across the whole deployment
        #
        # @param metric [String] requests or limits
        # @param type [String] cpu or memory
        # @return [Integer]
        def total_resource_allocation(metric, type)
          data.sum { |_, pod| pod[metric][type] || 0 }
        end

        # Graph width based on terminal size or specified max width
        #
        # @return [Integer]
        def graph_width
          return @graph_width if @graph_width
          return @graph_width = [[max_width, MIN_GRAPH_WIDTH].max, MAX_GRAPH_WIDTH].min if max_width.positive?

          begin
            width = IO.console.winsize[1]
          rescue NoMethodError
            width = DEFAULT_GRAPH_WIDTH
          end
          # Fallback to default if detection failed
          width = DEFAULT_GRAPH_WIDTH if width <= 0

          @graph_width = [[width, MIN_GRAPH_WIDTH].max, MAX_GRAPH_WIDTH].min
        end

        # Load metrics from metrics file
        #
        # @return [Hash]
        def load_metrics
          raise("Metrics file not found at #{metrics_file}") unless File.exist?(metrics_file)

          JSON.parse(File.read(metrics_file))
        end

        # Generate ASCII graphs
        #
        # @param values [Array<Hash>]
        # @param title [String]
        # @param unit [String]
        # @param request [Integer]
        # @param limit [Integer]
        # @return [void]
        def generate_ascii_graph(values, title, unit, request, limit)
          return "No data available for #{title}" if values.empty?

          values_max = values.max_by { |v| v[:val] }[:val]
          values_sum = values.sum { |v| v[:val] }.to_f
          graph_max = [values_max, request || 0, limit || 0].max

          statistics = ["Avg: #{(values_sum / values.length).round(1)}#{unit}", "Max: #{values_max}#{unit}"]

          statistics << if request
                          "Request: #{request}#{unit} (#{((values_max.to_f / request) * 100).round(1)}%)"
                        else
                          "Request: #{colorize('N/A', :red, bright: true)}"
                        end

          statistics << if limit
                          "Limit: #{limit}#{unit} (#{((values_max.to_f / limit) * 100).round(1)}%)"
                        else
                          "Limit: #{colorize('N/A', :red, bright: true)}"
                        end

          stat_line = statistics.join(" | ")

          header = [colorize("\n#{title}", :magenta)]
          header << colorize("=" * [title.length, stat_line.length].max, :magenta)
          header << colorize(stat_line, nil)

          log(header.join("\n"))
          log("")

          # Calculate effective graph width (subtract space for Y-axis labels and border)
          y_axis_width = 8
          effective_width = graph_width - y_axis_width

          print_y_axis(values, request, limit, effective_width, graph_max)
          print_x_axis(values, effective_width, y_axis_width)
        end

        # Print Y axis and metrics
        #
        # @param values [Array<Hash>]
        # @param request [Integer]
        # @param limit [Integer]
        # @param effective_width [Integer]
        # @param graph_max [Integer]
        # @return [void]
        def print_y_axis(values, request, limit, effective_width, graph_max)
          scale = graph_max.to_f / GRAPH_HEIGHT
          request_row = request ? (request / scale).ceil : 0
          limit_row = limit ? (limit / scale).ceil : 0

          # Print graph from top to bottom
          GRAPH_HEIGHT.downto(1) do |row|
            threshold = row * scale
            print format("%6.0f ", threshold)
            print "│"

            # Sample values to fit effective width
            sample_size = [values.length, effective_width].min
            step = values.length.to_f / sample_size

            sample_size.times do |i|
              index = (i * step).to_i
              value = values[index][:val]

              if !value.zero? && value >= threshold
                # Use different characters based on proximity to limit
                if limit && value > limit * 0.9
                  print "█"  # High usage (>90% of limit)
                elsif limit && value > limit * 0.7
                  print "▓"  # Medium usage (>70% of limit)
                else
                  print "▒"  # Normal usage
                end
              else
                print " "
              end
            end

            print_markers(request_row, limit_row, row)
            puts
          end
        end

        # Print markers for request and limit definitions
        #
        # @param request_row [Integer]
        # @param limit_row [Integer]
        # @param current_row [Integer]
        # @return [void]
        def print_markers(request_row, limit_row, current_row)
          # Show resource markers at correct positions
          markers = []
          markers << "← LIMIT" if limit_row == current_row
          markers << "← REQUEST" if request_row == current_row
          return unless markers.any?

          print " #{markers.join(', ')}"
        end

        # Print x-axis of the graph
        #
        # @param values [Array<Hash>]
        # @param effective_width [Integer]
        # @param y_axis_width [Integer]
        # @return [void]
        def print_x_axis(values, effective_width, y_axis_width)
          print "     0 "
          print "└"
          print "─" * effective_width
          puts "┘"

          # Time labels
          if values.length > 1
            first_entry_ts = Time.at(values.first[:ts]).utc.strftime("%H:%M:%S")
            last_entry_ts = Time.at(values.last[:ts]).utc.strftime("%H:%M:%S")

            print " " * y_axis_width
            print first_entry_ts
            # Calculate remaining space for last entry timestamp
            remaining_space = effective_width - first_entry_ts.length - 7
            print " " * [remaining_space, 0].max
            print last_entry_ts
            puts
          end

          puts
        end
      end
    end
  end
end
