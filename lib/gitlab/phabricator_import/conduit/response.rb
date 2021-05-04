# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Conduit
      class Response
        def self.parse!(http_response)
          unless http_response.success?
            raise Gitlab::PhabricatorImport::Conduit::ResponseError,
                  "Phabricator responded with #{http_response.status}"
          end

          response = new(Gitlab::Json.parse(http_response.body))

          unless response.success?
            raise ResponseError,
                  "Phabricator Error: #{response.error_code}: #{response.error_info}"
          end

          response
        rescue JSON::JSONError => e
          raise ResponseError, e
        end

        def initialize(json)
          @json = json
        end

        def success?
          error_code.nil?
        end

        def error_code
          json['error_code']
        end

        def error_info
          json['error_info']
        end

        def data
          json_result&.fetch('data')
        end

        def pagination
          return unless cursor_info = json_result&.fetch('cursor')

          @pagination ||= Pagination.new(cursor_info)
        end

        private

        attr_reader :json

        def json_result
          json['result']
        end
      end
    end
  end
end
