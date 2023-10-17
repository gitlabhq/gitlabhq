# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Attachments
        class ReleasesImporter < ::Gitlab::GithubImport::Importer::Attachments::BaseImporter
          def sidekiq_worker_class
            ::Gitlab::GithubImport::Attachments::ImportReleaseWorker
          end

          def collection_method
            :release_attachments
          end

          def object_type
            :release_attachment
          end

          def id_for_already_imported_cache(release)
            release.id
          end

          private

          def collection
            project.releases.id_not_in(already_imported_ids).select(:id, :description, :tag)
          end
        end
      end
    end
  end
end
