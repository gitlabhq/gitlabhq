#!/usr/bin/env ruby
# frozen_string_literal: true

if Object.const_defined?(:RSpec)
  # Ok, we're testing, we know we're going to stub `Gitlab`, so we just ignore
else
  require 'gitlab'

  if Gitlab.singleton_class.method_defined?(:com?)
    abort 'lib/gitlab.rb is loaded, and this means we can no longer load the client and we cannot proceed'
  end
end

require 'time'

class PreMergeChecks
  DEFAULT_API_ENDPOINT                                  = "https://gitlab.com/api/v4"
  MERGE_TRAIN_REF_REGEX                                 = %r{\Arefs/merge-requests/\d+/train\z}
  PIPELINE_FRESHNESS_DEFAULT_THRESHOLD_IN_HOURS         = 8
  PIPELINE_FRESHNESS_STABLE_BRANCHES_THRESHOLD_IN_HOURS = 72
  PREDICTIVE_PIPELINE_IDENTIFIER                        = 'predictive'
  REQUIRED_TIER_IDENTIFIER                              = 'tier:3'
  STABLE_BRANCH_SUFFIX                                  = '-stable-ee'
  TIER_IDENTIFIER_REGEX                                 = /tier:\d/

  PreMergeChecksFailedError = Class.new(StandardError)
  PreMergeChecksStatus = Struct.new(:exitstatus, :message) do
    def success?
      exitstatus == 0
    end
  end

  def initialize(
    api_endpoint: ENV.fetch('CI_API_V4_URL', DEFAULT_API_ENDPOINT),
    project_id: ENV['CI_PROJECT_ID'],
    merge_request_iid: ENV['CI_MERGE_REQUEST_IID'],
    target_branch: ENV['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'])
    @api_endpoint        = api_endpoint
    @project_id          = project_id
    @merge_request_iid   = merge_request_iid.to_i
    @target_branch       = target_branch
  end

  def execute
    check_required_ids!

    # Find the first non merge-train pipeline
    latest_pipeline_id = api_client.merge_request_pipelines(project_id, merge_request_iid).auto_paginate do |pipeline|
      next if pipeline.ref.match?(MERGE_TRAIN_REF_REGEX)

      break pipeline.id
    end
    fail_check!("Expected to have a latest pipeline but got none!") unless latest_pipeline_id

    latest_pipeline = api_client.pipeline(project_id, latest_pipeline_id)

    check_pipeline_for_merged_results!(latest_pipeline)
    check_pipeline_success!(latest_pipeline)
    check_pipeline_identifier!(latest_pipeline)
    check_pipeline_freshness!(latest_pipeline)

    PreMergeChecksStatus.new(0, "All good for merge! 🚀")
  rescue PreMergeChecksFailedError => ex
    PreMergeChecksStatus.new(1, ex.message)
  end

  private

  attr_reader :api_endpoint, :project_id, :merge_request_iid, :target_branch

  def api_client
    @api_client ||= begin
      Gitlab.configure do |config|
        config.endpoint = api_endpoint
        config.private_token = ENV.fetch('GITLAB_API_PRIVATE_TOKEN', '')
      end
      Gitlab.client
    end
  end

  def check_required_ids!
    fail_check!("Missing project_id!") unless project_id
    fail_check!("Missing merge_request_iid!") if merge_request_iid == 0
    fail_check!("Missing target_branch!") unless target_branch
  end

  def check_pipeline_for_merged_results!(pipeline)
    return if pipeline.ref == "refs/merge-requests/#{merge_request_iid}/merge"

    fail_check! <<~TEXT
      Expected to have a Merged Results pipeline but got #{pipeline.ref}!

      Please start a new pipeline.
    TEXT
  end

  def check_pipeline_success!(pipeline)
    return if pipeline.status == 'success'

    fail_check! <<~TEXT
      Expected latest pipeline (#{pipeline.web_url}) to be successful! Pipeline status was "#{pipeline.status}".

      Please start a new pipeline.
    TEXT
  end

  def check_pipeline_freshness!(pipeline)
    hours_ago = ((Time.now - Time.parse(pipeline.created_at)) / 3600).ceil(2)
    threshold =
      if target_branch_is_stable_branch?
        PIPELINE_FRESHNESS_STABLE_BRANCHES_THRESHOLD_IN_HOURS
      else
        PIPELINE_FRESHNESS_DEFAULT_THRESHOLD_IN_HOURS
      end

    return if hours_ago < threshold

    fail_check! <<~TEXT
      Expected latest pipeline (#{pipeline.web_url}) to be created within the last #{threshold} hours (it was created #{hours_ago} hours ago)!

      Please start a new pipeline.
    TEXT
  end

  def check_pipeline_identifier!(pipeline)
    if pipeline.name.match?(TIER_IDENTIFIER_REGEX)
      fail_check! <<~MSG unless pipeline.name.include?(REQUIRED_TIER_IDENTIFIER)
        Expected latest pipeline (#{pipeline.web_url}) to be a tier-3 pipeline! Pipeline name was "#{pipeline.name}".

        Please ensure the MR has all the required approvals, start a new pipeline and put the MR back on the Merge Train.
      MSG
    elsif pipeline.name.include?(PREDICTIVE_PIPELINE_IDENTIFIER)
      fail_check! <<~MSG
        Expected latest pipeline (#{pipeline.web_url}) not to be a predictive pipeline! Pipeline name was "#{pipeline.name}".

        Please ensure the MR has all the required approvals, start a new pipeline and put the MR back on the Merge Train.
      MSG
    end
  end

  def target_branch_is_stable_branch?
    target_branch.end_with?(STABLE_BRANCH_SUFFIX)
  end

  def fail_check!(text)
    raise PreMergeChecksFailedError, text
  end
end

if $PROGRAM_NAME == __FILE__
  require 'optparse'
  options = {}

  OptionParser.new do |opts|
    opts.on("-p", "--project_id [string]", String, "Project ID") do |value|
      options[:project_id] = value
    end

    opts.on("-m", "--merge_request_iid [string]", String, "Merge request IID") do |value|
      options[:merge_request_iid] = value
    end

    opts.on("-t", "--target-branch [string]", String, "Target branch name") do |value|
      options[:target_branch] = value
    end

    opts.on("-h", "--help") do
      puts "Usage: #{File.basename(__FILE__)} [--project_id <PROJECT_ID>] " \
        "[--merge_request_iid <MERGE_REQUEST_IID>] [--target-branch <TARGET_BRANCH>]"
      puts
      puts "Examples:"
      puts
      puts "#{File.basename(__FILE__)} --project_id \"gitlab-org/gitlab\" " \
        "--merge_request_iid \"1\" --target-branch \"master\""

      exit
    end
  end.parse!

  colors_to_codes = {
    red: 31,
    green: 32
  }.freeze

  pre_merge_checks_status = PreMergeChecks.new(**options).execute

  if pre_merge_checks_status.success?
    puts "\e[#{colors_to_codes[:green]}m#{pre_merge_checks_status.message}\e[0m"
  else
    puts "\e[#{colors_to_codes[:red]}m#{pre_merge_checks_status.message}\e[0m"
  end

  exit(pre_merge_checks_status.exitstatus)
end
