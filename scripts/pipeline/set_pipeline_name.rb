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
  DOCS                   = ['docs-lint markdown', 'docs-lint links'].freeze
  RSPEC_PREDICTIVE       = ['rspec:predictive:trigger', 'rspec-ee:predictive:trigger'].freeze
  CODE                   = ['retrieve-tests-metadata'].freeze
  QA_GDK                 = ['e2e:test-on-gdk'].freeze
  REVIEW_APP             = ['start-review-app-pipeline'].freeze
  QA                     = [
    'e2e:test-on-omnibus-ce',
    'e2e:test-on-omnibus-ee',
    'follow-up:e2e:test-on-omnibus-ee'
  ].freeze
  # Ordered by expected duration, DESC
  PIPELINE_TYPES_ORDERED = %w[qa review-app qa-gdk code rspec-predictive docs].freeze

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
    return unless ENV['CI_MERGE_REQUEST_LABELS']
    return if expedited_pipeline?

    tier_label = merge_request_labels.find { |label| label.start_with?('pipeline::tier-') }
    return if tier_label.nil?

    tier_label[/\d+\z/]
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
    merge_request_labels.any?('pipeline::expedited') ||
      # TODO: Remove once the label is renamed to be scoped
      merge_request_labels.any?('pipeline:expedite')
  end

  def pipeline_types
    return ['expedited'] if expedited_pipeline?

    types = Set.new

    api_client.pipeline_bridges(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID']).auto_paginate do |job|
      types.merge(pipeline_types_for(job))
    end

    api_client.pipeline_jobs(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID']).auto_paginate do |job|
      types.merge(pipeline_types_for(job))
    end

    types.sort_by { |type| PIPELINE_TYPES_ORDERED.index(type) }
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
    types << 'qa-gdk'           if QA_GDK.include?(job.name)
    types << 'review-app'       if REVIEW_APP.include?(job.name)
    types << 'qa'               if QA.include?(job.name)
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
