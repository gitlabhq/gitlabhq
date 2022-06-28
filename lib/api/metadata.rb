# frozen_string_literal: true

module API
  class Metadata < ::API::Base
    helpers ::API::Helpers::GraphqlHelpers
    include APIGuard

    allow_access_with_scope :read_user, if: -> (request) { request.get? || request.head? }

    before { authenticate! }

    feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

    METADATA_QUERY = <<~EOF
      {
        metadata {
          version
          revision
          kas {
            enabled
            externalUrl
            version
          }
        }
      }
    EOF

    desc 'Get the metadata information of the GitLab instance.' do
      detail 'This feature was introduced in GitLab 15.2.'
    end
    get '/metadata' do
      run_graphql!(
        query: METADATA_QUERY,
        context: { current_user: current_user },
        transform: ->(result) { result.dig('data', 'metadata') }
      )
    end
  end
end
