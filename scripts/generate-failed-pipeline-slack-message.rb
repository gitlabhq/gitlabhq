#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'json'

require_relative 'api/pipeline_failed_jobs'

class GenerateFailedPipelineSlackMessage
  DEFAULT_OPTIONS = {
    failed_pipeline_slack_message_file: 'failed_pipeline_slack_message.json',
    incident_json_file: 'incident.json'
  }.freeze

  def initialize(options)
    @incident_json_file = options.delete(:incident_json_file)
  end

  def execute
    {
      channel: ENV['SLACK_CHANNEL'],
      username: "Failed pipeline reporter",
      icon_emoji: ":boom:",
      text: "*#{title}*",
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*#{title}*"
          },
          accessory: {
            type: "button",
            text: {
              type: "plain_text",
              text: incident_button_text
            },
            url: incident_button_link
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*Branch*: #{branch_link}"
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*Commit*: #{commit_link}"
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*Triggered by* #{triggered_by_link} • *Source:* #{source} • *Duration:* #{pipeline_duration} minutes"
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*Failed jobs (#{failed_jobs.size}):* #{failed_jobs_list}"
          }
        }
      ]
    }
  end

  private

  attr_reader :incident_json_file

  def failed_jobs
    @failed_jobs ||= PipelineFailedJobs.new(API::DEFAULT_OPTIONS.dup.merge(exclude_allowed_to_fail_jobs: true)).execute
  end

  def title
    "#{project_link} pipeline #{pipeline_link} failed"
  end

  def incident_exist?
    return @incident_exist if defined?(@incident_exist)

    @incident_exist = File.exist?(incident_json_file)
  end

  def incident
    return unless incident_exist?

    @incident ||= JSON.parse(File.read(incident_json_file))
  end

  def incident_button_text
    if incident_exist?
      "View incident ##{incident['iid']}"
    else
      'Create incident'
    end
  end

  def incident_button_link
    if incident_exist?
      incident['web_url']
    else
      "#{ENV['CI_SERVER_URL']}/#{ENV['BROKEN_BRANCH_INCIDENTS_PROJECT']}/-/issues/new?" \
        "issuable_template=incident&issue%5Bissue_type%5D=incident"
    end
  end

  def pipeline_link
    "<#{ENV['CI_PIPELINE_URL']}|##{ENV['CI_PIPELINE_ID']}>"
  end

  def branch_link
    "<#{ENV['CI_PROJECT_URL']}/-/commits/#{ENV['CI_COMMIT_REF_NAME']}|`#{ENV['CI_COMMIT_REF_NAME']}`>"
  end

  def pipeline_duration
    ((Time.now - Time.parse(ENV['CI_PIPELINE_CREATED_AT'])) / 60.to_f).round(2)
  end

  def commit_link
    "<#{ENV['CI_PROJECT_URL']}/-/commit/#{ENV['CI_COMMIT_SHA']}|#{ENV['CI_COMMIT_TITLE']}>"
  end

  def source
    "`#{ENV['CI_PIPELINE_SOURCE']}#{schedule_type}`"
  end

  def schedule_type
    ENV['CI_PIPELINE_SOURCE'] == 'schedule' ? ": #{ENV['SCHEDULE_TYPE']}" : ''
  end

  def project_link
    "<#{ENV['CI_PROJECT_URL']}|#{ENV['CI_PROJECT_PATH']}>"
  end

  def triggered_by_link
    "<#{ENV['CI_SERVER_URL']}/#{ENV['GITLAB_USER_LOGIN']}|#{ENV['GITLAB_USER_NAME']}>"
  end

  def failed_jobs_list
    failed_jobs.map { |job| "<#{job.web_url}|#{job.name}>" }.join(', ')
  end
end

if $PROGRAM_NAME == __FILE__
  options = GenerateFailedPipelineSlackMessage::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-i", "--incident-json-file file_path", String, "Path to a file where the incident JSON data "\
      "can be found (defaults to "\
      "`#{GenerateFailedPipelineSlackMessage::DEFAULT_OPTIONS[:incident_json_file]}`)") do |value|
      options[:incident_json_file] = value
    end

    opts.on("-f", "--failed-pipeline-slack-message-file file_path", String, "Path to a file where to save the Slack "\
      "message (defaults to "\
      "`#{GenerateFailedPipelineSlackMessage::DEFAULT_OPTIONS[:failed_pipeline_slack_message_file]}`)") do |value|
      options[:failed_pipeline_slack_message_file] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  failed_pipeline_slack_message_file = options.delete(:failed_pipeline_slack_message_file)

  GenerateFailedPipelineSlackMessage.new(options).execute.tap do |message_payload|
    if failed_pipeline_slack_message_file
      File.write(failed_pipeline_slack_message_file, JSON.pretty_generate(message_payload))
    end
  end
end
