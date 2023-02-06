# frozen_string_literal: true

require 'gitlab'
require_relative 'default_options'

class CommitMergeRequests
  def initialize(options)
    @project = options.fetch(:project)
    @sha = options.fetch(:sha)

    # If api_token is nil, it's set to '' to allow unauthenticated requests (for forks).
    api_token = options.fetch(:api_token, '')

    warn "No API token given." if api_token.empty?

    @client = Gitlab.client(
      endpoint: options.fetch(:endpoint, API::DEFAULT_OPTIONS[:endpoint]),
      private_token: api_token
    )
  end

  def execute
    client.commit_merge_requests(project, sha)
  end

  private

  attr_reader :project, :sha, :client
end
