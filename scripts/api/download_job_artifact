#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'optparse'
require 'fileutils'
require 'uri'
require 'cgi'
require 'net/http'

class ArtifactFinder
  DEFAULT_OPTIONS = {
    project: ENV['CI_PROJECT_ID'],
    api_token: ENV['GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN']
  }.freeze

  def initialize(options)
    @project = options.delete(:project)
    @job_id = options.delete(:job_id)
    @api_token = options.delete(:api_token)
    @artifact_path = options.delete(:artifact_path)

    warn "No API token given." unless api_token
  end

  def execute
    url = "https://gitlab.com/api/v4/projects/#{CGI.escape(project)}/jobs/#{job_id}/artifacts"

    if artifact_path
      FileUtils.mkdir_p(File.dirname(artifact_path))
      url += "/#{artifact_path}"
    end

    fetch(url)
  end

  private

  attr_reader :project, :job_id, :api_token, :artifact_path

  def fetch(uri_str, limit = 10)
    raise 'Too many HTTP redirects' if limit == 0

    uri = URI(uri_str)
    request = Net::HTTP::Get.new(uri)
    request['Private-Token'] = api_token if api_token

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request) do |response|
        case response
        when Net::HTTPSuccess then
          File.open(artifact_path || 'artifacts.zip', 'w') do |file|
            response.read_body(&file.method(:write))
          end
        when Net::HTTPRedirection then
          location = response['location']
          warn "Redirected (#{limit - 1} redirections remaining)."
          fetch(location, limit - 1)
        else
          raise "Unexpected response: #{response.value}"
        end
      end
    end
  end
end

if $0 == __FILE__
  options = ArtifactFinder::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-p", "--project PROJECT", String, "Project where to find the job (defaults to $CI_PROJECT_ID)") do |value|
      options[:project] = value
    end

    opts.on("-j", "--job-id JOB_ID", String, "A job ID") do |value|
      options[:job_id] = value
    end

    opts.on("-a", "--artifact-path ARTIFACT_PATH", String, "A valid artifact path") do |value|
      options[:artifact_path] = value
    end

    opts.on("-t", "--api-token API_TOKEN", String, "A value API token with the `read_api` scope") do |value|
      options[:api_token] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  ArtifactFinder.new(options).execute
end
