# frozen_string_literal: true

module API
  class ImportGithubOauthWebhooks < ::API::Base
    feature_category :importers
    urgency :low

    helpers do
      # Overridden in EE. CE has no GitHub OAuth continuous sync feature, so there
      # is no webhook to verify.
      # rubocop:disable Gitlab/NoCodeCoverageComment -- overridden and tested in EE
      # :nocov:
      def receive_github_oauth_webhook!(_project)
        not_found!('Project')
      end
      # :nocov:
      # rubocop:enable Gitlab/NoCodeCoverageComment
    end

    resource :projects do
      desc 'Receive a GitHub webhook delivery for an OAuth-connected repository' do
        detail 'Verifies the webhook signature and, once available, triggers repository reconciliation.'
        success code: 200
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 429, message: 'Too many requests' }
        ]
        tags ['project_import']
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the project'
      end
      route_setting :authorization, skip_granular_token_authorization: :github_oauth_webhook_signature_auth
      post ':id/github/webhooks' do
        project = find_project(params[:id])
        not_found!('Project') unless project

        check_organization_maintenance_mode_for!(project)

        receive_github_oauth_webhook!(project)

        status :ok
      end
    end
  end
end

API::ImportGithubOauthWebhooks.prepend_mod
