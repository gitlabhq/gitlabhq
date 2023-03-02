# frozen_string_literal: true

require 'gitlab'
require_relative 'default_options'

class Base
  def initialize(options)
    @project = options.fetch(:project)

    # If api_token is nil, it's set to '' to allow unauthenticated requests (for forks).
    api_token = options[:api_token] || ''

    warn "No API token given." if api_token.empty?

    @client = Gitlab.client(
      endpoint: options.fetch(:endpoint, API::DEFAULT_OPTIONS[:endpoint]),
      private_token: api_token
    )
  end

  def execute
    raise NotImplementedError
  end

  private

  attr_reader :project, :client
end
