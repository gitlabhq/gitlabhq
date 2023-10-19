# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Attachments
        class MergeRequestsImporter < ::Gitlab::GithubImport::Importer::Attachments::BaseImporter
          def sidekiq_worker_class
            ::Gitlab::GithubImport::Attachments::ImportMergeRequestWorker
          end

          def collection_method
            :merge_request_attachments
          end

          def object_type
            :merge_request_attachment
          end

          def id_for_already_imported_cache(merge_request)
            merge_request.id
          end

          private

          def collection
            project.merge_requests.id_not_in(already_imported_ids).select(:id, :description, :iid)
          end

          def ordering_column
            :iid
          end
        end
      end
    end
  end
end
