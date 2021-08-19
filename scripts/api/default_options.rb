# frozen_string_literal: true

module API
  DEFAULT_OPTIONS = {
    project: ENV['CI_PROJECT_ID'],
    pipeline_id: ENV['CI_PIPELINE_ID'],
    # Default to "CI scripts API usage" at https://gitlab.com/gitlab-org/gitlab/-/settings/access_tokens
    api_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE'],
    endpoint: ENV['CI_API_V4_URL'] || 'https://gitlab.com/api/v4'
  }.freeze
end
