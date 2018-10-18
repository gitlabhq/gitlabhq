# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Remote < Base
            include Gitlab::Utils::StrongMemoize

            def content
              strong_memoize(:content) { fetch_remote_content }
            end

            private

            def validate_location!
              super

              unless ::Gitlab::UrlSanitizer.valid?(location)
                errors.push("Remote file `#{location}` does not have a valid address!")
              end
            end

            def fetch_remote_content
              Gitlab::HTTP.get(location)
            rescue SocketError
              errors.push("Remote file `#{location}` could not be fetched because of a socket error!")
              nil
            rescue Timeout::Error
              errors.push("Remote file `#{location}` could not be fetched because of a timeout error!")
              nil
            rescue Gitlab::HTTP::Error
              errors.push("Remote file `#{location}` could not be fetched because of a HTTP error!")
              nil
            rescue Gitlab::HTTP::BlockedUrlError
              errors.push("Remote file `#{location}` could not be fetched because the URL is blocked!")
              nil
            end
          end
        end
      end
    end
  end
end
