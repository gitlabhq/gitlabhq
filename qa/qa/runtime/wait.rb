module QA
  module Runtime
    class Wait
      attr_reader :options

      def initialize(*wait_options)
        @options = {
          default: 5,  # seconds
          time:    5,  # seconds
          poll:    1,  # second
          max:     60, # seconds
          reload:  true
        }.merge!(wait_options)
      end

      # hard sleep
      def sleep(time: @options[:time])
        start = Time.now

        while Time.now - start < @options[:max]
          result = yield
          return result if result

          Kernel.sleep(time)

          refresh if @options[:reload]
        end

        false
      end
    end
  end
end
