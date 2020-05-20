# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      module Parsers
        # Parses Helm v2 list (JSON) output
        class ListV2
          ParserError = Class.new(StandardError)

          attr_reader :contents, :json

          def initialize(contents)
            @contents = contents
            @json = Gitlab::Json.parse(contents)
          rescue JSON::ParserError => e
            raise ParserError, e.message
          end

          def releases
            @releases = helm_releases
          end

          private

          def helm_releases
            helm_releases = json['Releases'] || []

            raise ParserError, 'Invalid format for Releases' unless helm_releases.all? { |item| item.is_a?(Hash) }

            helm_releases
          end
        end
      end
    end
  end
end
