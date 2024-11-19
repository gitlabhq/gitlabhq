# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class IssuesPipeline
        include NdjsonPipeline

        relation_name 'issues'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation

        def delete_existing_records(entry)
          relation_hash = entry.first
          existing_record = portable.issues.iid_in(relation_hash['iid']).first

          return unless existing_record

          Issuable::DestroyService.new(container: portable, current_user: context.current_user)
            .execute(existing_record)
        end
      end
    end
  end
end

BulkImports::Projects::Pipelines::IssuesPipeline.prepend_mod
