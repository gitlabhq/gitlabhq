#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'json'

require_relative 'api/create_merge_request_discussion'
require_relative 'api/commit_merge_requests'
require_relative 'api/get_package_and_test_job'

class GenerateFailedPackageAndTestMrMessage
  DEFAULT_OPTIONS = {
    project: nil
  }.freeze

  def initialize(options)
    @project = options.fetch(:project)
  end

  def execute
    return unless failed_package_and_test_pipeline

    add_discussion_to_mr
  end

  private

  attr_reader :project

  def add_discussion_to_mr
    CreateMergeRequestDiscussion.new(
      API::DEFAULT_OPTIONS.merge(merge_request: merge_request)
    ).execute(content)
  end

  def failed_package_and_test_pipeline
    @failed_package_and_test_pipeline ||= GetPackageAndTestJob.new(API::DEFAULT_OPTIONS).execute
  end

  def merge_request
    @merge_request ||= CommitMergeRequests.new(
      API::DEFAULT_OPTIONS.merge(sha: ENV['CI_MERGE_REQUEST_SOURCE_BRANCH_SHA'])
    ).execute.first
  end

  def content
    <<~MARKDOWN
    :warning: @#{author_username} The `e2e:package-and-test-ee` child pipeline has failed.

    - `e2e:package-and-test-ee` pipeline: #{failed_package_and_test_pipeline['web_url']}

    `e2e:package-and-test-ee` pipeline is allowed to fail due its [flakiness](#{package_and_test_link}). Failures should be
    investigated to guarantee this backport complies with the Quality standards.

    Ping your team's associated Software Engineer in Test (SET) to confirm the failures are unrelated to the merge request.
    If there's no SET assigned, ask for assistance on the `#test-platform` Slack channel.
    MARKDOWN
  end

  def author_username
    merge_request['author']['username'] if merge_request
  end

  def package_and_test_link
    "https://about.gitlab.com/handbook/engineering/quality/quality-engineering/test-metrics-dashboards/#package-and-test"
  end
end

if $PROGRAM_NAME == __FILE__
  options = GenerateFailedPackageAndTestMrMessage::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  GenerateFailedPackageAndTestMrMessage.new(options).execute
end
