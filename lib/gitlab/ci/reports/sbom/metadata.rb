# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Metadata
          attr_accessor :tools, :authors, :properties, :timestamp

          def initialize(tools: [], authors: [], properties: [])
            @tools = tools
            @authors = authors
            @properties = properties
          end
        end
      end
    end
  end
end
