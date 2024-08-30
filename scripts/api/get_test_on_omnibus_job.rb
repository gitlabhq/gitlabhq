# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'
require_relative 'default_options'

class GetTestOnOmnibusJob
  FAILED_STATUS = [
    'failed',
    'passed with warnings',
    'canceled'
  ].freeze

  def initialize(options)
    @project = options.fetch(:project)
    @pipeline_id = options.fetch(:pipeline_id)

    # If api_token is nil, it's set to '' to allow unauthenticated requests (for forks).
    api_token = options.fetch(:api_token, '')

    warn "No API token given." if api_token.empty?

    @client = Gitlab.client(
      endpoint: options.fetch(:endpoint) || API::DEFAULT_OPTIONS[:endpoint],
      private_token: api_token
    )
  end

  def execute
    package_and_test_bridge = client
      .pipeline_bridges(project, pipeline_id, per_page: 100)
      .auto_paginate
      .find { |job| job.name.include?('test-on-omnibus-ee') }

    return if package_and_test_bridge&.downstream_pipeline.nil?

    package_and_test_pipeline = client
      .pipeline(project, package_and_test_bridge.downstream_pipeline.id)

    return if package_and_test_pipeline.nil?

    status = package_and_test_pipeline.detailed_status

    package_and_test_pipeline if FAILED_STATUS.include?(status&.label)
  end

  private

  attr_reader :project, :pipeline_id, :client
end
