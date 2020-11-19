# frozen_string_literal: true

module API
  class ImportGithub < ::API::Base
    feature_category :importers

    rescue_from Octokit::Unauthorized, with: :provider_unauthorized

    before do
      forbidden! unless Gitlab::CurrentSettings.import_sources&.include?('github')
    end

    helpers do
      def client
        @client ||= if Feature.enabled?(:remove_legacy_github_client)
                      Gitlab::GithubImport::Client.new(params[:personal_access_token], host: params[:github_hostname])
                    else
                      Gitlab::LegacyGithubImport::Client.new(params[:personal_access_token], client_options)
                    end
      end

      def access_params
        { github_access_token: params[:personal_access_token] }
      end

      def client_options
        { host: params[:github_hostname] }
      end

      def provider
        :github
      end

      def provider_unauthorized
        error!("Access denied to your #{Gitlab::ImportSources.title(provider.to_s)} account.", 401)
      end
    end

    desc 'Import a GitHub project' do
      detail 'This feature was introduced in GitLab 11.3.4.'
      success ::ProjectEntity
    end
    params do
      requires :personal_access_token, type: String, desc: 'GitHub personal access token'
      requires :repo_id, type: Integer, desc: 'GitHub repository ID'
      optional :new_name, type: String, desc: 'New repo name'
      requires :target_namespace, type: String, desc: 'Namespace to import repo into'
      optional :github_hostname, type: String, desc: 'Custom GitHub enterprise hostname'
    end
    post 'import/github' do
      result = Import::GithubService.new(client, current_user, params).execute(access_params, provider)

      if result[:status] == :success
        present ProjectSerializer.new.represent(result[:project])
      else
        status result[:http_status]
        { errors: result[:message] }
      end
    end
  end
end
