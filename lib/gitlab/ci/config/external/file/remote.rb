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

            def metadata
              super.merge(
                type: :remote,
                location: masked_location,
                blob: nil,
                raw: masked_location,
                extra: {}
              )
            end

            def validate_context!
              # no-op
            end

            def validate_location!
              super

              unless ::Gitlab::UrlSanitizer.valid?(location)
                errors.push("Remote file `#{masked_location}` does not have a valid address!")
              end
            end

            private

            def fetch_remote_content
              begin
                response = context.logger.instrument(:config_file_fetch_remote_content) do
                  Gitlab::HTTP.get(location)
                end
              rescue SocketError
                errors.push("Remote file `#{masked_location}` could not be fetched because of a socket error!")
              rescue Timeout::Error
                errors.push("Remote file `#{masked_location}` could not be fetched because of a timeout error!")
              rescue Gitlab::HTTP::Error
                errors.push("Remote file `#{masked_location}` could not be fetched because of HTTP error!")
              rescue Errno::ECONNREFUSED, Gitlab::HTTP::BlockedUrlError => e
                errors.push("Remote file could not be fetched because #{e}!")
              end

              if response&.code.to_i >= 400
                errors.push("Remote file `#{masked_location}` could not be fetched because of HTTP code `#{response.code}` error!")
              end

              response.body if errors.none?
            end
          end
        end
      end
    end
  end
end
