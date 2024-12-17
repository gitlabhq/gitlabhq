# frozen_string_literal: true

module API
  class ImportBitbucketServer < ::API::Base
    feature_category :importers
    urgency :low

    before do
      set_current_organization
    end

    helpers do
      def client
        @client ||= BitbucketServer::Client.new(credentials)
      end

      def credentials
        @credentials ||= {
          base_uri: params[:bitbucket_server_url],
          user: params[:bitbucket_server_username],
          password: params[:personal_access_token]
        }
      end
    end

    desc 'Import a BitBucket Server repository' do
      detail 'This feature was introduced in GitLab 13.2.'
      success ::ProjectEntity
      failure [
        { code: 400, message: 'Bad request' },
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' },
        { code: 422, message: 'Unprocessable entity' },
        { code: 503, message: 'Service unavailable' }
      ]
      tags ['project_import_bitbucket']
    end

    params do
      requires :bitbucket_server_url, type: String, desc: 'Bitbucket Server URL'
      requires :bitbucket_server_username, type: String, desc: 'BitBucket Server Username'
      requires :personal_access_token, type: String, desc: 'BitBucket Server personal access token/password'
      requires :bitbucket_server_project, type: String, desc: 'BitBucket Server Project Key'
      requires :bitbucket_server_repo, type: String, desc: 'BitBucket Server Repository Name'
      optional :new_name, type: String, desc: 'New repo name'
      optional :new_namespace, type: String, desc: 'Namespace to import repo into'
      optional :timeout_strategy, type: String, values: ::ProjectImportData::TIMEOUT_STRATEGIES,
        desc: 'Strategy for behavior on timeouts'
    end

    post 'import/bitbucket_server' do
      result = Import::BitbucketServerService.new(client, current_user,
        params.merge(organization_id: Current.organization.id)).execute(credentials)

      if result[:status] == :success
        present ProjectSerializer.new.represent(result[:project], serializer: :import)
      else
        render_api_error!({ error: result[:message] }, result[:http_status])
      end
    end
  end
end
