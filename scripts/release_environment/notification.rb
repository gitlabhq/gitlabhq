#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
class ReleaseEnvironmentNotification
  OPS_RELEASE_TOOLS_API_URL = "https://ops.gitlab.net/api/v4/projects/130"

  def initialize
    raise "Missing required environment variable." unless set_required_env_vars?

    @version = fetch_version
  end

  def execute
    response = trigger_notification
    puts "Response body: #{response.body}"

    return if response.is_a? Net::HTTPSuccess

    raise "Something was wrong when triggering the notification pipeline. Response code: #{response.code}"
  end

  attr_reader :version

  private

  def set_required_env_vars?
    # List of required environment variables.
    # CI_PIPELINE_URL supposes to be set by the CI pipeline, so we don't check it.
    required_env_vars = %w[ENVIRONMENT VERSIONS OPS_RELEASE_TOOLS_PIPELINE_TOKEN RELEASE_ENVIRONMENT_NOTIFICATION_TYPE]

    required_env_vars.each do |var|
      if ENV.fetch(var, nil).to_s.empty?
        puts "Missing required environment variable: #{var}"
        return false
      end
    end
  end

  # Get the version from the VERSIONS environment variable
  # All components use the same version, so we can just get the version of gitlab
  def fetch_version
    versions_data.fetch('gitlab', nil)
  end

  def versions_data
    JSON.parse(ENV.fetch('VERSIONS', '{}'))
  end

  def trigger_notification
    uri = URI.parse("#{OPS_RELEASE_TOOLS_API_URL}/trigger/pipeline")
    request = Net::HTTP::Post.new(uri)

    data = {
      "variables[RELEASE_ENVIRONMENT_PIPELINE]" => "true",
      "variables[RELEASE_ENVIRONMENT_NOTIFICATION_TYPE]" => ENV.fetch('RELEASE_ENVIRONMENT_NOTIFICATION_TYPE', nil),
      "variables[RELEASE_ENVIRONMENT_CI_PIPELINE_URL]" => ENV.fetch('CI_PIPELINE_URL', nil),
      "variables[RELEASE_ENVIRONMENT_NAME]" => ENV.fetch('ENVIRONMENT', nil),
      "variables[RELEASE_ENVIRONMENT_VERSION]" => version,
      "token" => ENV.fetch('OPS_RELEASE_TOOLS_PIPELINE_TOKEN', nil),
      "ref" => "master"
    }
    request.set_form_data(data)

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end
end

ReleaseEnvironmentNotification.new.execute if $PROGRAM_NAME == __FILE__
