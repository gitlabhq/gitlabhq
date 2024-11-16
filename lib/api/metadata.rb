# frozen_string_literal: true

module API
  class Metadata < ::API::Base
    helpers ::API::Helpers::GraphqlHelpers
    include APIGuard

    allow_access_with_scope [:read_user, :ai_features], if: ->(request) { request.get? || request.head? }

    before { authenticate! }

    METADATA_TAGS = %w[metadata].freeze

    feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

    METADATA_QUERY = <<~EOF
      {
        metadata {
          version
          revision
          kas {
            enabled
            externalUrl
            externalK8sProxyUrl
            version
          }
          enterprise
        }
      }
    EOF

    helpers do
      def run_metadata_query
        run_graphql!(
          query: METADATA_QUERY,
          context: { current_user: current_user },
          transform: ->(result) { result.dig('data', 'metadata') }
        )
      end
    end

    desc 'Retrieve metadata information for this GitLab instance' do
      detail 'This feature was introduced in GitLab 15.2.'
      success Entities::Metadata
      failure [
        { code: 401, message: 'Unauthorized' }
      ]
      tags METADATA_TAGS
    end
    get '/metadata' do
      run_metadata_query
    end

    # Support the deprecated `/version` route.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/366287
    desc 'Retrieves version information for the GitLab instance' do
      detail 'This feature was introduced in GitLab 8.13 and deprecated in 15.5. ' \
             'We recommend you instead use the Metadata API.'
      success Entities::Metadata
      failure [
        { code: 401, message: 'Unauthorized' }
      ]
      tags METADATA_TAGS
    end

    get '/version' do
      run_metadata_query
    end
  end
end
