#!/usr/bin/env ruby
# frozen_string_literal: true

require 'time'
require 'gitlab' unless Object.const_defined?(:Gitlab)

class PreMergeChecks
  DEFAULT_API_ENDPOINT = "https://gitlab.com/api/v4"
  MERGE_TRAIN_REF_REGEX = %r{\Arefs/merge-requests/\d+/train\z}
  TIER_IDENTIFIER_REGEX = /tier:\d/
  REQUIRED_TIER_IDENTIFIER = 'tier:3'
  PREDICTIVE_PIPELINE_IDENTIFIER = 'predictive'
  PIPELINE_FRESHNESS_THRESHOLD_IN_HOURS = 4

  def initialize(
    api_endpoint: ENV.fetch('CI_API_V4_URL', DEFAULT_API_ENDPOINT),
    project_id: ENV['CI_PROJECT_ID'],
    merge_request_iid: ENV['CI_MERGE_REQUEST_IID'])
    @api_endpoint        = api_endpoint
    @project_id          = project_id
    @merge_request_iid   = merge_request_iid.to_i

    check_required_ids!
  end

  def execute
    # Find the first non merge-train pipeline
    latest_pipeline_id = api_client.merge_request_pipelines(project_id, merge_request_iid).auto_paginate do |pipeline|
      next if pipeline.ref.match?(MERGE_TRAIN_REF_REGEX)

      break pipeline.id
    end
    raise "Expected to have a latest pipeline but got none!" unless latest_pipeline_id

    latest_pipeline = api_client.pipeline(project_id, latest_pipeline_id)

    check_pipeline_for_merged_results!(latest_pipeline)
    check_pipeline_freshness!(latest_pipeline)
    check_pipeline_identifier!(latest_pipeline)

    puts "All good for merge! 🚀"
  end

  private

  attr_reader :api_endpoint, :project_id, :merge_request_iid

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
    raise 'Missing project_id' unless project_id
    raise 'Missing merge_request_iid' if merge_request_iid == 0
  end

  def check_pipeline_for_merged_results!(pipeline)
    return if pipeline.ref == "refs/merge-requests/#{merge_request_iid}/merge"

    raise "Expected to have a Merged Results pipeline but got #{pipeline.ref}!"
  end

  def check_pipeline_freshness!(pipeline)
    hours_ago = ((Time.now - Time.parse(pipeline.created_at)) / 3600).ceil(2)
    return if hours_ago < PIPELINE_FRESHNESS_THRESHOLD_IN_HOURS

    raise "Expected latest pipeline to be created within the last 4 hours (it was created #{hours_ago} hours ago)!"
  end

  def check_pipeline_identifier!(pipeline)
    if pipeline.name.match?(TIER_IDENTIFIER_REGEX)
      raise <<~MSG unless pipeline.name.include?(REQUIRED_TIER_IDENTIFIER)
        Expected latest pipeline to be a tier-3 pipeline!

        Please ensure the MR has all the required approvals, start a new pipeline and put the MR back on the Merge Train.
      MSG
    elsif pipeline.name.include?(PREDICTIVE_PIPELINE_IDENTIFIER)
      raise <<~MSG
        Expected latest pipeline not to be a predictive pipeline!

        Please ensure the MR has all the required approvals, start a new pipeline and put the MR back on the Merge Train.
      MSG
    end
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

    opts.on("-h", "--help") do
      puts "Usage: #{File.basename(__FILE__)} [--project_id <PROJECT_ID>] [--merge_request_iid <MERGE_REQUEST_IID>]"
      puts
      puts "Examples:"
      puts
      puts "#{File.basename(__FILE__)} --project_id \"gitlab-org/gitlab\" --merge_request_iid \"1\""

      exit
    end
  end.parse!

  PreMergeChecks.new(**options).execute
end
