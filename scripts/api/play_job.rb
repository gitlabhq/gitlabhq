#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'gitlab'
require 'optparse'
require_relative 'get_job_id'

class PlayJob
  DEFAULT_OPTIONS = {
    project: ENV['CI_PROJECT_ID'],
    pipeline_id: ENV['CI_PIPELINE_ID'],
    api_token: ENV['GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN']
  }.freeze

  def initialize(options)
    @options = options

    Gitlab.configure do |config|
      config.endpoint = 'https://gitlab.com/api/v4'
      config.private_token = options.fetch(:api_token)
    end
  end

  def execute
    job = JobFinder.new(options.slice(:project, :api_token, :pipeline_id, :job_name).merge(scope: 'manual')).execute

    Gitlab.job_play(project, job.id)
  end

  private

  attr_reader :options

  def project
    options[:project]
  end
end

if $0 == __FILE__
  options = PlayJob::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-p", "--project PROJECT", String, "Project where to find the job (defaults to $CI_PROJECT_ID)") do |value|
      options[:project] = value
    end

    opts.on("-j", "--job-name JOB_NAME", String, "A job name that needs to exist in the found pipeline") do |value|
      options[:job_name] = value
    end

    opts.on("-t", "--api-token API_TOKEN", String, "A value API token with the `read_api` scope") do |value|
      options[:api_token] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  PlayJob.new(options).execute
end
