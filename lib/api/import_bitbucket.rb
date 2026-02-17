# frozen_string_literal: true

module API
  class ImportBitbucket < ::API::Base
    before do
      authenticate!
      set_current_organization
    end

    feature_category :importers
    urgency :low

    desc 'Import a BitBucket Cloud repository' do
      detail 'This feature was introduced in GitLab 17.0.'
      success ::ProjectImportEntity
      failure [
        { code: 400, message: 'Bad request' },
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' },
        { code: 422, message: 'Unprocessable entity' },
        { code: 503, message: 'Service unavailable' }
      ]
      tags ['project_import']
    end

    params do
      optional :bitbucket_username, type: String, desc: 'BitBucket username (for app passwords)'
      optional :bitbucket_app_password, type: String, desc: 'BitBucket app password'
      optional :bitbucket_email, type: String, desc: 'BitBucket email (for API tokens)'
      optional :bitbucket_api_token, type: String, desc: 'BitBucket API token'
      requires :repo_path, type: String, desc: 'Repository path'
      requires :target_namespace, type: String, desc: 'Target namespace'
      optional :new_name, type: String, desc: 'New repository name'
      all_or_none_of :bitbucket_username, :bitbucket_app_password
      all_or_none_of :bitbucket_email, :bitbucket_api_token
      mutually_exclusive :bitbucket_app_password, :bitbucket_api_token
      at_least_one_of :bitbucket_app_password, :bitbucket_api_token
    end

    route_setting :authorization, permissions: :create_bitbucket_import,
      boundaries: [{ boundary_type: :group, boundary_param: :target_namespace }, { boundary_type: :user }]
    post 'import/bitbucket' do
      result = Import::BitbucketService.new(
        current_user,
        params.merge(organization_id: Current.organization.id)
      ).execute

      if result[:status] == :success
        present ProjectSerializer.new.represent(result[:project], serializer: :import)
      else
        render_api_error!({ error: result[:message] }, result[:http_status])
      end
    end
  end
end
