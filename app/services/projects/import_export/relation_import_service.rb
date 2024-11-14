# frozen_string_literal: true

# Imports a selected relation into an existing project, skipping any identified
# duplicates. Duplicates are matched on the `iid` of the record being imported.
module Projects
  module ImportExport
    class RelationImportService
      include ::Services::ReturnServiceResponses

      IMPORTABLE_RELATIONS = %w[issues merge_requests milestones ci_pipelines].freeze

      # Creates a new RelationImportService.
      #
      # @param [User] current_user
      # @param [Hash] params
      # @option params [String] path The full path of the project
      # @option params [String] relation The relation to import. See IMPORTABLE_RELATIONS for permitted values.
      # @option params [UploadedFile] file The export archive containing the data to import
      def initialize(current_user:, params:)
        @current_user = current_user
        @params = params
      end

      # Checks the validity of the chosen project and triggers the re-import of
      # the chosen relation.
      #
      # @return [Services::ServiceResponse]
      def execute
        return error(_('Project not found'), :not_found) unless project

        unless relation_valid?
          return error(
            format(
              _('Imported relation must be one of %{relations}'),
              relations: IMPORTABLE_RELATIONS.to_sentence(last_word_connector: ', or ')
            ),
            :bad_request
          )
        end

        return error(_('You are not authorized to perform this action'), :forbidden) unless user_permitted?
        return error(_('A relation import is already in progress for this project'), :conflict) if import_in_progress?

        tracker = create_status_tracker

        unless tracker.persisted?
          return error(
            format(
              _('Relation import could not be created: %{errors}'),
              errors: tracker.errors.full_messages.to_sentence
            ),
            :bad_request
          )
        end

        attach_import_file

        Projects::ImportExport::RelationImportWorker.perform_async(
          tracker.id,
          current_user.id
        )

        success(tracker)
      end

      private

      attr_reader :current_user, :params

      def user_permitted?
        Ability.allowed?(current_user, :admin_project, project)
      end

      def relation_valid?
        IMPORTABLE_RELATIONS.include?(params[:relation])
      end

      def attach_import_file
        import_export_upload = project.import_export_upload_by_user(current_user) ||
          project.import_export_uploads.new(user: current_user)

        import_export_upload.import_file = params[:file]
        import_export_upload.save
      end

      def create_status_tracker
        project.relation_import_trackers.create(
          relation: params[:relation]
        )
      end

      def project
        @project ||= Project.find_by_full_path(params[:path])
      end

      def import_in_progress?
        project.any_import_in_progress?
      end
    end
  end
end
