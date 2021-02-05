# frozen_string_literal: true

module API
  class Version < ::API::Base
    helpers ::API::Helpers::GraphqlHelpers
    include APIGuard

    allow_access_with_scope :read_user, if: -> (request) { request.get? || request.head? }

    before { authenticate! }

    feature_category :not_owned

    METADATA_QUERY = <<~EOF
      {
        metadata {
          version
          revision
        }
      }
    EOF

    desc 'Get the version information of the GitLab instance.' do
      detail 'This feature was introduced in GitLab 8.13.'
    end
    get '/version' do
      run_graphql!(
        query: METADATA_QUERY,
        context: { current_user: current_user },
        transform: ->(result) { result.dig('data', 'metadata') }
      )
    end
  end
end
