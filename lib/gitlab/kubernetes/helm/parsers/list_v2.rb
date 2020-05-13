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
            @releases ||= json["Releases"] || []
          end
        end
      end
    end
  end
end
