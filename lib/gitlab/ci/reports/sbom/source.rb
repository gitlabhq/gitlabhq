# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Source
          include ::Sbom::SourceHelper

          attr_reader :source_type, :data

          def initialize(type:, data:)
            @source_type = type
            @data = data
          end
        end
      end
    end
  end
end
