#!/usr/bin/env ruby
# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
if Object.const_defined?(:RSpec)
  # Ok, we're testing, we know we're going to stub `Gitlab`, so we just ignore
else
  require 'gitlab'

  if Gitlab.singleton_class.method_defined?(:com?)
    abort 'lib/gitlab.rb is loaded, and this means we can no longer load the client and we cannot proceed'
  end
end

require 'net/http'

class SetPipelineName
  DOCS = ['docs-lint markdown', 'docs-lint links'].freeze
  RSPEC_PREDICTIVE = ['rspec:predictive:trigger', 'rspec-ee:predictive:trigger'].freeze
  CODE = ['retrieve-tests-metadata'].freeze
  E2E_GDK = ['e2e:test-on-gdk'].freeze
  E2E_CNG = ['e2e:test-on-cng'].freeze
  E2E_OMNIBUS = ['e2e:test-on-omnibus-ee', 'e2e:test-on-omnibus-ce'].freeze
  REVIEW_APP = ['start-review-app-pipeline'].freeze
  # Ordered by expected duration, DESC
  PIPELINE_TYPES_ORDERED = %w[e2e-omnibus review-app e2e-gdk e2e-cng code rspec-predictive docs].freeze

  # We need an access token that isn't CI_JOB_TOKEN because we are querying
  # the pipelines API to fetch jobs and bridge jobs.
  # We are still using CI_JOB_TOKEN to update the pipeline name.
  #
  # See https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html for more info.
  def initialize(api_endpoint:, gitlab_access_token:)
    @api_endpoint        = api_endpoint
    @gitlab_access_token = gitlab_access_token
  end

  def execute
    # If we already added metadata to the pipeline name, we discard it, and recompute it.
    #
    # This is in case we retry a CI job that runs this script.
    pipeline_name = ENV['CI_PIPELINE_NAME'].sub(/ \[.*\]\z/, '')

    pipeline_suffixes         = {}
    pipeline_suffixes[:tier]  = pipeline_tier || 'N/A'
    pipeline_suffixes[:types] = pipeline_types.join(',')
    pipeline_suffixes[:opts]  = pipeline_opts.join(',')

    pipeline_suffix = pipeline_suffixes.map { |key, value| "#{key}:#{value}" }.join(', ')
    pipeline_name += " [#{pipeline_suffix}]"

    puts "New pipeline name: #{pipeline_name}"

    set_pipeline_name(pipeline_name)
  rescue Gitlab::Error::Error => error
    puts "GitLab error: #{error}"
    allow_to_fail_return_code
  end

  private

  attr_reader :api_endpoint, :gitlab_access_token

  def api_client
    @api_client ||= Gitlab.client(
      endpoint: api_endpoint,
      private_token: gitlab_access_token
    )
  end

  def pipeline_tier
    return if expedited_pipeline?

    # the pipeline tier is detected by the `pipeline-tier-<tier>` job name.
    pipeline_jobs.each do |job|
      next unless job.name.start_with?('pipeline-tier-')

      return job.name[/\d+\z/]
    end

    nil
  end

  def merge_request_labels
    # The first pipeline of any MR won't have any tier label, unless the label was added in the MR description
    # before creating the MR. This is a known limitation.
    #
    # Fetching the labels from the API instead of relying on ENV['CI_MERGE_REQUEST_LABELS']
    # would solve this problem, but it would also mean that we would update the tier information
    # based on the merge request labels at the time of retrying the job, which isn't what we want.
    @merge_request_labels ||= ENV.fetch('CI_MERGE_REQUEST_LABELS', '').split(',').tap do |labels|
      puts "Labels from the MR: #{labels}"
    end
  end

  def expedited_pipeline?
    merge_request_labels.any?('pipeline::expedited')
  end

  def pipeline_types
    return ['expedited'] if expedited_pipeline?

    types = pipeline_jobs.each_with_object(Set.new) do |job, types|
      types.merge(pipeline_types_for(job))
    end

    types.sort_by { |type| PIPELINE_TYPES_ORDERED.index(type) }
  end

  def pipeline_jobs
    @pipeline_jobs ||= []

    return @pipeline_jobs if @pipeline_jobs.any?

    api_client.pipeline_bridges(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID']).auto_paginate do |job|
      @pipeline_jobs << job
    end

    api_client.pipeline_jobs(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID']).auto_paginate do |job|
      @pipeline_jobs << job
    end

    @pipeline_jobs
  end

  def pipeline_opts
    return [] unless ENV['CI_MERGE_REQUEST_LABELS']

    opts_label = merge_request_labels.select { |label| label.start_with?(/pipeline:\w/) }
    return if opts_label.nil?

    opts_label.map { |opt_label| opt_label.delete_prefix('pipeline:') }
  end

  def pipeline_types_for(job)
    types = Set.new
    types << 'rspec-predictive' if RSPEC_PREDICTIVE.include?(job.name)
    types << 'e2e-gdk'          if E2E_GDK.include?(job.name)
    types << 'e2e-cng'          if E2E_CNG.include?(job.name)
    # omnibus e2e tests are manual in mr pipelines and are only executed on demand
    types << 'e2e-omnibus'      if E2E_OMNIBUS.include?(job.name) && job.status != 'manual'
    types << 'review-app'       if REVIEW_APP.include?(job.name)
    types << 'docs'             if DOCS.include?(job.name)
    types << 'code'             if CODE.include?(job.name)
    types
  end

  def set_pipeline_name(pipeline_name)
    # TODO: Replace with the following once a version of the gem is above 4.19.0:
    #
    # Gitlab.update_pipeline_metadata(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID'], name: pipeline_name)
    #
    # New endpoint added in https://github.com/NARKOZ/gitlab/pull/685 (merged on 2024-04-30)
    # Latest release was made on 2022-07-10: https://github.com/NARKOZ/gitlab/releases/tag/v4.19.0
    uri = URI("#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_PROJECT_ID']}/pipelines/#{ENV['CI_PIPELINE_ID']}/metadata")
    success = false
    error   = nil
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Put.new uri
      request['JOB-TOKEN'] = ENV['CI_JOB_TOKEN']
      request.body = "name=#{pipeline_name}"
      response = http.request request

      if response.code == '200'
        success = true
      else
        error = response.body
      end
    end

    return 0 if success

    puts "Failed to set pipeline name: #{error}"
    allow_to_fail_return_code
  end

  # Exit with a different error code, so that we can allow the CI job to fail
  def allow_to_fail_return_code
    3
  end
end

if $PROGRAM_NAME == __FILE__
  exit SetPipelineName.new(
    api_endpoint: ENV['CI_API_V4_URL'],
    gitlab_access_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE']
  ).execute
end
