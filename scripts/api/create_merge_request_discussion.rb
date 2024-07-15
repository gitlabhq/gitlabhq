# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'
require_relative 'default_options'

class CreateMergeRequestDiscussion
  def initialize(options)
    @merge_request = options.fetch(:merge_request)
    @project = options.fetch(:project)

    # If api_token is nil, it's set to '' to allow unauthenticated requests (for forks).
    api_token = options.fetch(:api_token, '')

    warn "No API token given." if api_token.empty?

    @client = Gitlab.client(
      endpoint: options.fetch(:endpoint, API::DEFAULT_OPTIONS[:endpoint]),
      private_token: api_token
    )
  end

  def execute(content)
    client.create_merge_request_discussion(
      project,
      merge_request.fetch('iid'),
      body: content
    )
  end

  private

  attr_reader :merge_request, :client, :project
end
