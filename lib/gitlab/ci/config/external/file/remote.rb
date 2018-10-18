# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Remote < Base
            include Gitlab::Utils::StrongMemoize
            attr_reader :location

            def content
              strong_memoize(:content) { fetch_remote_content }
            end

            def error_message
              "Remote file '#{location}' is not valid."
            end

            private

            def fetch_remote_content
              Gitlab::HTTP.get(location)
            rescue Gitlab::HTTP::Error, Timeout::Error, SocketError, Gitlab::HTTP::BlockedUrlError
              nil
            end
          end
        end
      end
    end
  end
end
