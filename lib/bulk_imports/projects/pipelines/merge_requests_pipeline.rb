# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class MergeRequestsPipeline
        include NdjsonPipeline

        relation_name 'merge_requests'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation

        def delete_existing_records(entry)
          relation_hash = entry.first
          existing_record = portable.merge_requests.iid_in(relation_hash['iid']).first

          return unless existing_record

          Issuable::DestroyService.new(container: portable, current_user: context.current_user)
            .execute(existing_record)
        end

        def on_finish
          ::Projects::ImportExport::AfterImportMergeRequestsWorker.perform_async(context.portable.id)
        end
      end
    end
  end
end
