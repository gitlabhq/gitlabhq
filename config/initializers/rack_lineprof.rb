# frozen_string_literal: true

# The default colors of rack-lineprof can be very hard to look at in terminals
# with darker backgrounds. This patch tweaks the colors a bit so the output is
# actually readable.
if Rails.env.development? && RUBY_ENGINE == 'ruby' && ENV['ENABLE_LINEPROF']
  Rails.application.config.middleware.use(Rack::Lineprof)

  module Rack
    class Lineprof
      class Sample < Rack::Lineprof::Sample.superclass
        def format(*)
          formatted = if level == CONTEXT
                        sprintf "                 | % 3i  %s", line, code
                      else
                        sprintf "% 8.1fms %5i | % 3i  %s", ms, calls, line, code
                      end

          case level
          when CRITICAL
            color.red formatted
          when WARNING
            color.yellow formatted
          when NOMINAL
            color.white formatted
          else # CONTEXT
            formatted
          end
        end
      end
    end
  end
end
