#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'json'

require_relative 'api/pipeline_failed_jobs'
require_relative 'api/create_issue'
require_relative 'api/create_issue_discussion'

class CreatePipelineFailureIncident
  DEFAULT_OPTIONS = {
    project: nil,
    incident_json_file: 'incident.json'
  }.freeze
  DEFAULT_LABELS = ['Engineering Productivity', 'master-broken:undetermined'].freeze

  def initialize(options)
    @project = options.delete(:project)
    @api_token = options.delete(:api_token)
  end

  def execute
    payload = {
      issue_type: 'incident',
      title: title,
      description: description,
      labels: incident_labels
    }

    CreateIssue.new(project: project, api_token: api_token).execute(payload).tap do |incident|
      CreateIssueDiscussion.new(project: project, api_token: api_token)
        .execute(issue_iid: incident.iid, body: "## Root Cause Analysis")
      CreateIssueDiscussion.new(project: project, api_token: api_token)
        .execute(issue_iid: incident.iid, body: "## Investigation Steps")
    end
  end

  private

  attr_reader :project, :api_token

  def failed_jobs
    @failed_jobs ||= PipelineFailedJobs.new(API::DEFAULT_OPTIONS.dup.merge(exclude_allowed_to_fail_jobs: true)).execute
  end

  def now
    @now ||= Time.now.utc
  end

  def title
    @title ||= begin
      full_title = "#{now.strftime('%A %F %R UTC')} - `#{ENV['CI_PROJECT_PATH']}` " \
        "broken `#{ENV['CI_COMMIT_REF_NAME']}` with #{failed_jobs.map(&:name).join(', ')}"

      if full_title.size >= 255
        "#{full_title[...252]}..." # max title length is 255, and we add an elipsis
      else
        full_title
      end
    end
  end

  def description
    <<~MARKDOWN
    ## #{project_link} pipeline #{pipeline_link} failed

    **Branch: #{branch_link}**

    **Commit: #{commit_link}**

    **Triggered by** #{triggered_by_link} • **Source:** #{source} • **Duration:** #{pipeline_duration} minutes

    **Failed jobs (#{failed_jobs.size}):**

    #{failed_jobs_list}

    ### General guidelines

    Follow the [Broken `master` handbook guide](https://about.gitlab.com/handbook/engineering/workflow/#broken-master).

    ### Investigation

    **Be sure to fill the `Timeline` for this incident.**

    1. If the failure is new, and looks like a potential flaky failure, you can retry the failing job.
      Make sure to mention the retry in the `Timeline` and leave a link to the retried job.
    1. If the failure looks like a broken `master`, communicate the broken `master` in Slack using the "Broadcast Master Broken" workflow:
       - Click the Shortcut lightning bolt icon in the `#master-broken` channel and select "Broadcast Master Broken".
       - Click "Continue the broadcast" after the automated message in `#master-broken`.

    ### Pre-resolution

    If you believe that there's an easy resolution by either:

    - Reverting a particular merge request.
    - Making a quick fix (for example, one line or a few similar simple changes in a few lines).
      You can create a merge request, assign to any available maintainer, and ping people that were involved/related to the introduction of the failure.
      Additionally, a message can be posted in `#backend_maintainers` or `#frontend_maintainers` to get a maintainer take a look at the fix ASAP.

    In both cases, make sure to add the ~"pipeline:expedite" label, and `master:broken` or `master:foss-broken` label, to speed up the `master`-fixing pipelines.

    ### Resolution

    Follow [the Resolution steps from the handbook](https://about.gitlab.com/handbook/engineering/workflow/#responsibilities-of-the-resolution-dri).
    MARKDOWN
  end

  def incident_labels
    master_broken_label =
      if ENV['CI_PROJECT_NAME'] == 'gitlab-foss'
        'master:foss-broken'
      else
        'master:broken'
      end

    DEFAULT_LABELS.dup << master_broken_label
  end

  def pipeline_link
    "[##{ENV['CI_PIPELINE_ID']}](#{ENV['CI_PIPELINE_URL']})"
  end

  def branch_link
    "[`#{ENV['CI_COMMIT_REF_NAME']}`](#{ENV['CI_PROJECT_URL']}/-/commits/#{ENV['CI_COMMIT_REF_NAME']})"
  end

  def pipeline_duration
    ((Time.now - Time.parse(ENV['CI_PIPELINE_CREATED_AT'])) / 60.to_f).round(2)
  end

  def commit_link
    "[#{ENV['CI_COMMIT_TITLE']}](#{ENV['CI_PROJECT_URL']}/-/commit/#{ENV['CI_COMMIT_SHA']})"
  end

  def source
    "`#{ENV['CI_PIPELINE_SOURCE']}`"
  end

  def project_link
    "[#{ENV['CI_PROJECT_PATH']}](#{ENV['CI_PROJECT_URL']})"
  end

  def triggered_by_link
    "[#{ENV['GITLAB_USER_NAME']}](#{ENV['CI_SERVER_URL']}/#{ENV['GITLAB_USER_LOGIN']})"
  end

  def failed_jobs_list_for_title
    failed_jobs.map(&:name).join(', ')
  end

  def failed_jobs_list
    failed_jobs.map { |job| "- [#{job.name}](#{job.web_url})" }.join("\n")
  end
end

if $PROGRAM_NAME == __FILE__
  options = CreatePipelineFailureIncident::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-p", "--project PROJECT", String, "Project where to create the incident (defaults to "\
      "`#{CreatePipelineFailureIncident::DEFAULT_OPTIONS[:project]}`)") do |value|
      options[:project] = value
    end

    opts.on("-f", "--incident-json-file file_path", String, "Path to a file where to save the incident JSON data "\
      "(defaults to `#{CreatePipelineFailureIncident::DEFAULT_OPTIONS[:incident_json_file]}`)") do |value|
      options[:incident_json_file] = value
    end

    opts.on("-t", "--api-token API_TOKEN", String, "A valid Project token with the `Reporter` role and `api` scope "\
      "to create the incident") do |value|
      options[:api_token] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  incident_json_file = options.delete(:incident_json_file)

  CreatePipelineFailureIncident.new(options).execute.tap do |incident|
    File.write(incident_json_file, JSON.pretty_generate(incident.to_h)) if incident_json_file
  end
end
