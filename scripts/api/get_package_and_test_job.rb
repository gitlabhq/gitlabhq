# frozen_string_literal: true

require 'gitlab'

require_relative 'default_options'

class GetPackageAndTestJob
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
    package_and_test_job = nil

    client.pipeline_bridges(project, pipeline_id, scope: 'failed', per_page: 100).auto_paginate do |job|
      if job['name'].include?('package-and-test')
        package_and_test_job = job
        break
      end
    end

    package_and_test_job
  end

  private

  attr_reader :project, :pipeline_id, :exclude_allowed_to_fail_jobs, :client
end
