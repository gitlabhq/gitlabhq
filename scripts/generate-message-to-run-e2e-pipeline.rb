#!/usr/bin/env ruby

# frozen_string_literal: true

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
      :warning: @#{author_username} Some end-to-end (E2E) tests have been selected based on the stage label on this MR.
      If not run already, please run the `e2e:package-and-test-ee` job in the `qa` stage
      and review the results **before merging this MR**. (E2E tests are not run automatically on some MRs due to [runner resource constraints](https://gitlab.com/gitlab-org/gitlab-qa/-/issues/261).)

      If you would like to run all e2e tests, please apply the ~"pipeline:run-all-e2e" label and restart the pipeline.

      Once done, please apply the ✅ emoji on this comment.

      For any questions or help in reviewing the E2E test results, please reach out on the internal #quality Slack channel.
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
