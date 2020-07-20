# frozen_string_literal: true

module Banzai
  module Pipeline
    module JiraImport
      class AdfCommonmarkPipeline < BasePipeline
        def self.filters
          FilterArray[
            Filter::JiraImport::AdfToCommonmarkFilter
          ]
        end
      end
    end
  end
end
