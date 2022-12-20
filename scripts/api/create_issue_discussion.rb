# frozen_string_literal: true

require 'gitlab'
require_relative 'default_options'

class CreateIssueDiscussion
  def initialize(options)
    @project = options.fetch(:project)

    # Force the token to be a string so that if api_token is nil, it's set to '',
    # allowing unauthenticated requests (for forks).
    api_token = options.delete(:api_token).to_s

    warn "No API token given." if api_token.empty?

    @client = Gitlab.client(
      endpoint: options.delete(:endpoint) || API::DEFAULT_OPTIONS[:endpoint],
      private_token: api_token
    )
  end

  def execute(discussion_data)
    client.post(
      "/projects/#{client.url_encode project}/issues/#{discussion_data.delete(:issue_iid)}/discussions",
      body: discussion_data
    )
  end

  private

  attr_reader :project, :client
end
