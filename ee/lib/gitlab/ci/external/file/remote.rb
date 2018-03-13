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
                Gitlab::HTTP.get(location, allow_local_requests: true)
              rescue Gitlab::HTTP::Error, Timeout::Error, SocketError
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
