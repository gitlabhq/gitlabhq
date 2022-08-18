# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Source
          attr_reader :source_type, :data, :fingerprint

          def initialize(source = {})
            @source_type = source['type']
            @data = source['data']
            @fingerprint = source['fingerprint']
          end
        end
      end
    end
  end
end
