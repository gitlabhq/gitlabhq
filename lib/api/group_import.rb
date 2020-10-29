# frozen_string_literal: true

module API
  class GroupImport < ::API::Base
    feature_category :importers

    helpers Helpers::FileUploadHelpers

    helpers do
      def parent_group
        find_group!(params[:parent_id]) if params[:parent_id].present?
      end

      def authorize_create_group!
        if parent_group
          authorize! :create_subgroup, parent_group
        else
          authorize! :create_group
        end
      end

      def closest_allowed_visibility_level
        if parent_group
          Gitlab::VisibilityLevel.closest_allowed_level(parent_group.visibility_level)
        else
          Gitlab::VisibilityLevel::PRIVATE
        end
      end
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Workhorse authorize the group import upload' do
        detail 'This feature was introduced in GitLab 12.8'
      end
      post 'import/authorize' do
        require_gitlab_workhorse!

        Gitlab::Workhorse.verify_api_request!(headers)

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

        ImportExportUploader.workhorse_authorize(
          has_length: false,
          maximum_size: Gitlab::CurrentSettings.max_import_size.megabytes
        )
      end

      desc 'Create a new group import' do
        detail 'This feature was introduced in GitLab 12.8'
        success Entities::Group
      end
      params do
        requires :path, type: String, desc: 'Group path'
        requires :name, type: String, desc: 'Group name'
        requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The group export file to be imported'
        optional :parent_id, type: Integer, desc: "The ID of the parent group that the group will be imported into. Defaults to the current user's namespace."
      end
      post 'import' do
        authorize_create_group!
        require_gitlab_workhorse!
        validate_file!

        group_params = {
          path: params[:path],
          name: params[:name],
          parent_id: params[:parent_id],
          visibility_level: closest_allowed_visibility_level,
          import_export_upload: ImportExportUpload.new(import_file: params[:file])
        }

        group = ::Groups::CreateService.new(current_user, group_params).execute

        if group.persisted?
          ::Groups::ImportExport::ImportService.new(group: group, user: current_user).async_execute

          accepted!
        else
          render_api_error!("Failed to save group #{group.errors.messages}", 400)
        end
      end
    end
  end
end
