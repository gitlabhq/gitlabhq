module Gitlab
  module Ci
    module External
      module File
        class Remote < Base
          include Gitlab::Utils::StrongMemoize
          attr_reader :location

          def content
            return @content if defined?(@content)

            @content = strong_memoize(:content) do
              begin
                HTTParty.get(location)
              rescue HTTParty::Error, Timeout::Error, SocketError
                nil
              end
            end
          end

          def error_message
            "Remote file '#{location}' is not valid."
          end
        end
      end
    end
  end
end
