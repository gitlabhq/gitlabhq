#!/usr/bin/env ruby

# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'
require 'optparse'

require_relative 'api/create_merge_request_note'
require_relative 'api/commit_merge_requests'

class GenerateMessageToRunE2ePipeline
  NOTE_PATTERN = /<!-- Run e2e warning begin -->[\s\S]+<!-- Run e2e warning end -->/

  def initialize(options)
    @options = options
    @project = @options.fetch(:project)

    # If api_token is nil, it's set to '' to allow unauthenticated requests (for forks).
    api_token = @options.fetch(:api_token, '')

    warn "No API token given." if api_token.empty?

    @client = ::Gitlab.client(
      endpoint: options.fetch(:endpoint),
      private_token: api_token
    )
  end

  def execute
    return unless qa_tests_folders?

    add_note_to_mr unless existing_note
  end

  private

  attr_reader :project, :client, :options

  def qa_tests_folders?
    return unless File.exist?(env('ENV_FILE'))

    qa_tests_line = File.open(env('ENV_FILE')).detect { |line| line.include?("QA_TESTS=") }
    qa_tests_match = qa_tests_line&.match(/'([\s\S]+)'/)

    qa_tests_match && !qa_tests_match[1].include?('_spec.rb') # rubocop:disable Rails/NegateInclude
  end

  def add_note_to_mr
    CreateMergeRequestNote.new(
      options.merge(merge_request: merge_request)
    ).execute(content)
  end

  def match?(body)
    body.match?(NOTE_PATTERN)
  end

  def existing_note
    @note ||= client.merge_request_comments(project, merge_request.iid).auto_paginate.detect do |note|
      match?(note.body)
    end
  end

  def merge_request
    @merge_request ||= CommitMergeRequests.new(
      options.merge(sha: ENV['CI_MERGE_REQUEST_SOURCE_BRANCH_SHA'])
    ).execute.first
  end

  def content
    <<~MARKDOWN
      <!-- Run e2e warning begin -->
      @#{author_username} Some end-to-end (E2E) tests should run based on the stage label.

      Please start the `manual:e2e-test-pipeline-generate` job in the `prepare` stage and wait for the tests in the `follow-up:e2e:test-on-omnibus-ee` pipeline
      to pass **before merging this MR**. Do not use **Auto-merge**, unless these tests have already completed successfully, because a failure in these tests do not block the auto-merge.
      (E2E tests are computationally intensive and don't run automatically for every push/rebase, so we ask you to run this job manually at least once.)

      To run all E2E tests, apply the ~"pipeline:run-all-e2e" label and run a new pipeline.

      E2E test jobs are allowed to fail due to [flakiness](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/dashboards).
      See current failures at the latest [pipeline triage issue](https://gitlab.com/gitlab-org/quality/pipeline-triage/-/issues).

      Once done, apply the ✅ emoji on this comment.

      **Team members only:** for any questions or help, reach out on the internal `#test-platform` Slack channel.
      <!-- Run e2e warning end -->
    MARKDOWN
  end

  def author_username
    merge_request&.author&.username
  end

  def env(name)
    return unless ENV[name] && !ENV[name].strip.empty?

    ENV[name]
  end
end

if $PROGRAM_NAME == __FILE__
  OptionParser.new do |opts|
    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  GenerateMessageToRunE2ePipeline.new(API::DEFAULT_OPTIONS).execute
end
