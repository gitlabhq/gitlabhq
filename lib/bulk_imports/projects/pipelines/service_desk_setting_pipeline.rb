# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ServiceDeskSettingPipeline
        include NdjsonPipeline

        relation_name 'service_desk_setting'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
