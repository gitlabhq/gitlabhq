#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'json'

require_relative 'api/create_merge_request_discussion'
require_relative 'api/commit_merge_requests'
require_relative 'api/get_test_on_omnibus_job'

class GenerateFailedTestOnOmnibusMrMessage
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
    @failed_package_and_test_pipeline ||= GetTestOnOmnibusJob.new(API::DEFAULT_OPTIONS).execute
  end

  def merge_request
    @merge_request ||= CommitMergeRequests.new(
      API::DEFAULT_OPTIONS.merge(sha: ENV['CI_MERGE_REQUEST_SOURCE_BRANCH_SHA'])
    ).execute.first
  end

  def content
    <<~MARKDOWN
    :warning: @#{author_username} The `e2e:test-on-omnibus-ee` child pipeline has failed.

    - `e2e:test-on-omnibus-ee` pipeline: #{failed_package_and_test_pipeline['web_url']}

    `e2e:test-on-omnibus-ee` pipeline is allowed to fail due its [flakiness](#{package_and_test_link}). Failures should be
    investigated to guarantee this backport complies with GitLab's quality standards.

    If you're unsure whether this failure is legitimate, please reach out to the `#s_developer_experience` Slack channel
    to verify that the failures are not related to the merge request.

    ([_improve this message_](https://gitlab.com/gitlab-org/gitlab/-/edit/master/scripts/generate-failed-test-on-omnibus-mr-message.rb))
    MARKDOWN
  end

  def author_username
    merge_request['author']['username'] if merge_request
  end

  def package_and_test_link
    "https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/developer-experience/dashboards/"
  end
end

if $PROGRAM_NAME == __FILE__
  options = GenerateFailedTestOnOmnibusMrMessage::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  GenerateFailedTestOnOmnibusMrMessage.new(options).execute
end
