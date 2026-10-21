# frozen_string_literal: true

require 'net/http'
require 'open3'
require 'uri'
require 'json'
require 'time'
require 'gitlab'

# Annotates database-testing result comments on a merge request as stale once a newer
# commit has been pushed to the source branch.
class MarkPipelineComments
  DB_PIPELINE_NOTE_TAG = 'gitlab-org/database-team/gitlab-com-database-testing:identifiable-note'
  INVALIDATED_RESULTS_MSG_TAG = 'gitlab-org/database-team/gitlab-com-database-testing:identifiable-note-invalidated'

  INVALIDATED_RESULTS_MSG = <<~MSG.freeze
    ## ⚠️

    Please note that the database testing pipeline results in this comment
    are no longer valid due to a commit being added to the merge request that has
    changed one or more files.

    Please run another database testing pipeline for the most accurate results.

    <!-- #{INVALIDATED_RESULTS_MSG_TAG} -->
    ***

  MSG

  # timestamp_override lets a caller that already knows the source branch tip skip the git
  # work entirely. env supplies the repository URL and branch the fetch needs.
  def initialize(merge_request_id:, project_path:, client:, env: ENV, timestamp_override: nil)
    @merge_request_id = merge_request_id
    @project_path = project_path
    @client = client
    @env = env
    @timestamp_override = timestamp_override
  end

  def execute
    puts "Fetching discussions on merge request #{merge_request_id}"

    client.merge_request_notes(project_path, merge_request_id).auto_paginate.each do |discussion|
      next unless discussion.body.include?(DB_PIPELINE_NOTE_TAG)
      next if discussion.body.include?(INVALIDATED_RESULTS_MSG_TAG)

      puts "Found discussion #{discussion.id} which was created at #{discussion.created_at}"
      puts "Last committed timestamp is #{most_recent_commit_timestamp}"
      next unless Time.iso8601(discussion.created_at) < most_recent_commit_timestamp

      puts "Annotating body of #{discussion.id}"
      client.edit_merge_request_note(
        project_path, merge_request_id, discussion.id, "#{INVALIDATED_RESULTS_MSG}#{discussion.body}"
      )
    end
  end

  private

  attr_reader :merge_request_id, :project_path, :client, :env, :timestamp_override

  # Only needed once a note that could be invalidated has been found, and resolving it costs a
  # fetch. Most runs find none: this job runs on every merge request pipeline touching
  # `db-patterns`, while `db:gitlabcom-database-testing`, which posts the notes, is manual.
  def most_recent_commit_timestamp
    @most_recent_commit_timestamp ||= resolve_most_recent_commit_timestamp
  end

  def resolve_most_recent_commit_timestamp
    return Time.at(timestamp_override.to_i) unless timestamp_override.nil? || timestamp_override.empty?

    branch = env.fetch('CI_MERGE_REQUEST_SOURCE_BRANCH_NAME')
    ref = "refs/remotes/origin/#{branch}"
    refspec = "+#{branch}:#{ref}"

    # The clone-gitlab-repo artifact has no job token in .git/config, and the private security
    # mirror rejects anonymous fetches, so fetch through the token URL. --depth=1 is enough:
    # only the tip commit's own timestamp is read. git's own output goes to stderr on failure.
    fetched = system('git', 'fetch', '--depth=1', env.fetch('CI_REPOSITORY_URL'), refspec, out: File::NULL)
    raise "Failed to fetch #{branch} to resolve its most recent commit timestamp" unless fetched

    # A failed or empty read would become Time.at(0), and since no note predates 1970 that
    # would silently invalidate nothing. Fail loudly instead.
    timestamp, status = Open3.capture2('git', 'log', '-1', '--format=%at', ref)
    raise "Failed to read the commit timestamp of #{ref}" unless status.success? && !timestamp.strip.empty?

    Time.at(timestamp.to_i)
  end
end

if $PROGRAM_NAME == __FILE__
  unless ENV['CI']
    puts 'Necessary environment variable CI not defined.'
    exit(-1)
  end

  MarkPipelineComments.new(
    merge_request_id: ARGV[0],
    project_path: ENV.fetch('CI_PROJECT_PATH'),
    client: Gitlab.client(
      endpoint: ENV.fetch('CI_API_V4_URL'),
      private_token: ENV.fetch('DATABASE_PROJECT_TOKEN')
    ),
    timestamp_override: ARGV[1]
  ).execute
end
