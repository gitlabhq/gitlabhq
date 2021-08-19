#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require 'optparse'
require_relative 'default_options'

class CancelPipeline
  def initialize(options)
    @project = options.delete(:project)
    @pipeline_id = options.delete(:pipeline_id)

    @client = Gitlab.client(
      endpoint: options.delete(:endpoint) || API::DEFAULT_OPTIONS[:endpoint],
      private_token: options.delete(:api_token)
    )
  end

  def execute
    client.cancel_pipeline(project, pipeline_id)
  end

  private

  attr_reader :project, :pipeline_id, :client
end

if $0 == __FILE__
  options = API::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-p", "--project PROJECT", String, "Project where to find the job (defaults to $CI_PROJECT_ID)") do |value|
      options[:project] = value
    end

    opts.on("-i", "--pipeline-id PIPELINE_ID", String, "A pipeline ID (defaults to $CI_PIPELINE_ID)") do |value|
      options[:pipeline_id] = value
    end

    opts.on("-t", "--api-token API_TOKEN", String, "A value API token with the `api` scope") do |value|
      options[:api_token] = value
    end

    opts.on("-E", "--endpoint ENDPOINT", String, "The API endpoint for the API token. (defaults to $CI_API_V4_URL and fallback to https://gitlab.com/api/v4)") do |value|
      options[:endpoint] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  CancelPipeline.new(options).execute
end
