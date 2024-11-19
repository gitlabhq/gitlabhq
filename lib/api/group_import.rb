# frozen_string_literal: true

module API
  class GroupImport < ::API::Base
    feature_category :importers
    urgency :low

    helpers Helpers::FileUploadHelpers

    before do
      set_current_organization
    end

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
        tags ['group_import']
      end
      post 'import/authorize' do
        require_gitlab_workhorse!

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

        ImportExportUploader.workhorse_authorize(
          has_length: false,
          maximum_size: Gitlab::CurrentSettings.max_import_size.megabytes
        )
      end

      desc 'Create a new group import' do
        detail 'This feature was introduced in GitLab 12.8'
        success code: 202
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 400, message: 'Bad request' },
          { code: 503, message: 'Service unavailable' }
        ]
        consumes ['multipart/form-data']
        tags ['group_import']
      end
      params do
        requires :path, type: String, desc: 'Group path'
        requires :name, type: String, desc: 'Group name'
        requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The group export file to be imported', documentation: { type: 'file' }
        optional :parent_id, type: Integer, desc: "The ID of the parent group that the group will be imported into. Defaults to the current user's namespace."
        optional :organization_id, type: Integer, default: -> { Current.organization_id }, desc: "The ID of the organization that the group will be part of. "
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
          import_export_upload: ImportExportUpload.new(import_file: params[:file], user: current_user),
          organization_id: params[:organization_id]
        }

        response = ::Groups::CreateService.new(current_user, group_params).execute
        group = response[:group]

        if response.success?
          ::Groups::ImportExport::ImportService.new(group: group, user: current_user).async_execute

          accepted!
        else
          render_api_error!("Failed to save group #{group.errors.messages}", 400)
        end
      end
    end
  end
end
