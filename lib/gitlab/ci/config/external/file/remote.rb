# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Remote < Base
            include Gitlab::Utils::StrongMemoize

            def initialize(params, context)
              @location = params[:remote]

              super
            end

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
              begin
                response = Gitlab::HTTP.get(location)
              rescue SocketError
                errors.push("Remote file `#{location}` could not be fetched because of a socket error!")
              rescue Timeout::Error
                errors.push("Remote file `#{location}` could not be fetched because of a timeout error!")
              rescue Gitlab::HTTP::Error
                errors.push("Remote file `#{location}` could not be fetched because of HTTP error!")
              rescue Gitlab::HTTP::BlockedUrlError => e
                errors.push("Remote file could not be fetched because #{e}!")
              end

              if response&.code.to_i >= 400
                errors.push("Remote file `#{location}` could not be fetched because of HTTP code `#{response.code}` error!")
              end

              response.to_s if errors.none?
            end
          end
        end
      end
    end
  end
end
