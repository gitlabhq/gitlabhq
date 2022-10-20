#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'api/pipeline_failed_jobs'

finder_options = API::DEFAULT_OPTIONS.dup.merge(exclude_allowed_to_fail_jobs: true)
failed_jobs = PipelineFailedJobs.new(finder_options).execute

class SlackReporter
  DEFAULT_FAILED_PIPELINE_REPORT_FILE = 'failed_pipeline_report.json'

  def initialize(failed_jobs)
    @failed_jobs = failed_jobs
    @failed_pipeline_report_file = ENV.fetch('FAILED_PIPELINE_REPORT_FILE', DEFAULT_FAILED_PIPELINE_REPORT_FILE)
  end

  def report
    payload = {
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
          }
        },
        {
          type: "section",
          fields: [
            {
              type: "mrkdwn",
              text: "*Commit*\n#{commit_link}"
            },
            {
              type: "mrkdwn",
              text: "*Triggered by*\n#{triggered_by_link}"
            }
          ]
        },
        {
          type: "section",
          fields: [
            {
              type: "mrkdwn",
              text: "*Source*\n#{source} from #{project_link}"
            },
            {
              type: "mrkdwn",
              text: "*Duration*\n#{pipeline_duration} minutes"
            }
          ]
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

    File.write(failed_pipeline_report_file, JSON.pretty_generate(payload))
  end

  private

  attr_reader :failed_jobs, :failed_pipeline_report_file

  def title
    "Pipeline #{pipeline_link} for #{branch_link} failed"
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
    "`#{ENV['CI_PIPELINE_SOURCE']}`"
  end

  def project_link
    "<#{ENV['CI_PROJECT_URL']}|#{ENV['CI_PROJECT_NAME']}>"
  end

  def triggered_by_link
    "<#{ENV['CI_SERVER_URL']}/#{ENV['GITLAB_USER_LOGIN']}|#{ENV['GITLAB_USER_NAME']}>"
  end

  def failed_jobs_list
    failed_jobs.map { |job| "<#{job.web_url}|#{job.name}>" }.join(', ')
  end
end

SlackReporter.new(failed_jobs).report
