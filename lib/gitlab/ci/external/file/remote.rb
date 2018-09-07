module Gitlab
  module Ci
    module External
      module File
        class Remote
          attr_reader :value

          def initialize(value)
            @value = value
          end

          def valid?
            ::Gitlab::UrlSanitizer.valid?(value) && content
          end

          def content
            HTTParty.get(value)
          rescue HTTParty::Error, Timeout::Error
            false
          end
        end
      end
    end
  end
end
