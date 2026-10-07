# frozen_string_literal: true

module API
  class ImportBitbucket < ::API::Base
    before do
      authenticate!
    end

    feature_category :importers
    urgency :low

    helpers do
      def bitbucket_import_boundary
        import_target_boundary(Namespace.find_by_full_path(params[:target_namespace]))
      end
    end

    desc 'Import repository from Bitbucket Cloud' do
      detail 'Imports a repository from Bitbucket Cloud to GitLab. Prerequisites: - The prerequisites for ' \
        'Bitbucket Cloud importer. This feature was introduced in GitLab 17.0.'
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
      requires :bitbucket_email, type: String, desc: 'BitBucket email'
      requires :bitbucket_api_token, type: String, desc: 'BitBucket API token'
      requires :repo_path, type: String, desc: 'Repository path'
      requires :target_namespace, type: String, desc: 'Target namespace'
      optional :new_name, type: String, desc: 'New repository name'
    end

    route_setting :authorization, permissions: :create_bitbucket_import,
      boundary: -> { bitbucket_import_boundary },
      boundaries: [{ boundary_type: :group }, { boundary_type: :user }]
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
