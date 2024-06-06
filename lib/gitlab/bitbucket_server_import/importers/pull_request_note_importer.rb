# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class PullRequestNoteImporter
        include Loggable

        def initialize(project, hash)
          @project = project
          @object = hash.with_indifferent_access
        end

        def execute
          return unless import_data_valid?

          log_info(import_stage: 'import_pull_request_note', message: 'starting', iid: object[:iid])

          import

          log_info(import_stage: 'import_pull_request_note', message: 'finished', iid: object[:iid])
        end

        private

        attr_reader :object, :project

        def import
          merge_request = project.merge_requests.find_by(iid: object[:iid]) # rubocop: disable CodeReuse/ActiveRecord -- no need to move this to ActiveRecord model
          if merge_request.nil?
            log_info(import_stage: 'import_pull_request_note', message: 'skipped', iid: object[:iid])

            return
          end

          importer = notes_importer_class(object[:comment_type])
          if importer
            importer.new(project, merge_request).execute(object[:comment])
          else
            log_debug(
              message: 'UNSUPPORTED_EVENT_TYPE',
              comment_type: object[:comment_type], comment_id: object[:comment_id]
            )
          end
        end

        def notes_importer_class(comment_type)
          case comment_type
          when 'approved_event'
            Gitlab::BitbucketServerImport::Importers::PullRequestNotes::ApprovedEvent
          when 'declined_event'
            Gitlab::BitbucketServerImport::Importers::PullRequestNotes::DeclinedEvent
          when 'inline'
            Gitlab::BitbucketServerImport::Importers::PullRequestNotes::Inline
          when 'merge_event'
            Gitlab::BitbucketServerImport::Importers::PullRequestNotes::MergeEvent
          when 'standalone_notes'
            Gitlab::BitbucketServerImport::Importers::PullRequestNotes::StandaloneNotes
          end
        end

        def import_data_valid?
          project.import_data&.credentials && project.import_data&.data
        end
      end
    end
  end
end
