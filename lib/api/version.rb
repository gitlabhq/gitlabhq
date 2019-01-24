# frozen_string_literal: true

module API
  class Version < Grape::API
    helpers ::API::Helpers::GraphqlHelpers

    before { authenticate! }

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
      conditionally_graphql!(
        query: METADATA_QUERY,
        context: { current_user: current_user },
        transform: ->(result) { result.dig('data', 'metadata') },
        fallback: -> { { version: Gitlab::VERSION, revision: Gitlab.revision } }
      )
    end
  end
end
