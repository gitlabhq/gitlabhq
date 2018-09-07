module Gitlab
  module Ci
    module External
      module File
        class Remote
          attr_reader :location

          def initialize(location, opts = {})
            @location = location
          end

          def valid?
            ::Gitlab::UrlSanitizer.valid?(location) && content
          end

          def content
            return @content if defined?(@content)

            @content ||= begin
                           HTTParty.get(location)
                         rescue HTTParty::Error, Timeout::Error
                           false
                         end
          end
        end
      end
    end
  end
end
