# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class MergeRequestsPipeline
        include NdjsonPipeline

        relation_name 'merge_requests'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation

        def after_run(_)
          context.portable.merge_requests.set_latest_merge_request_diff_ids!
        end
      end
    end
  end
end
