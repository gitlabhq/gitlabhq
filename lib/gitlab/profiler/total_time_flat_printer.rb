module Gitlab
  module Profiler
    class TotalTimeFlatPrinter < RubyProf::FlatPrinter
      def max_percent
        @options[:max_percent] || 100
      end

      # Copied from:
      #   <https://github.com/ruby-prof/ruby-prof/blob/master/lib/ruby-prof/printers/flat_printer.rb>
      #
      # The changes are just to filter by total time, not self time, and add a
      # max_percent option as well.
      def print_methods(thread)
        total_time = thread.total_time
        methods = thread.methods.sort_by(&sort_method).reverse

        sum = 0
        methods.each do |method|
          total_percent = (method.total_time / total_time) * 100
          next if total_percent < min_percent
          next if total_percent > max_percent

          sum += method.self_time

          @output << "%6.2f  %9.3f %9.3f %9.3f %9.3f %8d  %s%s\n" % [
            method.self_time / total_time * 100, # %self
            method.total_time,                   # total
            method.self_time,                    # self
            method.wait_time,                    # wait
            method.children_time,                # children
            method.called,                       # calls
            method.recursive? ? "*" : " ",       # cycle
            method_name(method)                  # name
          ]
        end
      end
    end
  end
end
