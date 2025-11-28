# frozen_string_literal: true

require_relative 'helpers/groups'
require_relative 'helpers/gitlab_api_helper'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep.
  # This keep will fetch any `test` + `failure::flaky-test` + `flakiness::1` issues,
  # without the `QA` nor `quarantine` labels and open quarantine merge requests for them.
  #
  # You can run it individually with:
  #
  # ```
  # gdk start db
  # bundle exec gitlab-housekeeper -d \
  #   -k Keeps::QuarantineFlakyTests
  # ```
  class QuarantineFlakyTests < ::Gitlab::Housekeeper::Keep
    QUERY_URL_TEMPLATE = "https://gitlab.com/api/v4/projects/69718754/issues/?order_by=updated_at&state=opened&labels[]=test&labels[]=failure::flaky-test&labels[]=%<flakiness_label>s&not[labels][]=QA&not[labels][]=quarantine&per_page=20"
    # https://rubular.com/r/OoeQIEwPkL1m7E
    EXAMPLE_LINE_REGEX = /\bit (?<description_and_metadata>[\w'",: \#\{\}]*(?:,\n)?[\w\'",: ]+?) do$/m
    FLAKINESS_LABELS = %w[flakiness::1 flakiness::2 severity::1].freeze

    def each_identified_change
      FLAKINESS_LABELS.each do |flakiness_label|
        query_url = very_flaky_issues_query_url(flakiness_label)

        each_very_flaky_issue(query_url) do |flaky_issue|
          next unless valid_flaky_issue?(flaky_issue)

          change = ::Gitlab::Housekeeper::Change.new
          change.context = { flaky_issue: flaky_issue }
          change.identifiers = build_identifiers(flaky_issue)
          yield(change)
        end
      end
    end

    def make_change!(change)
      flaky_issue = change.context[:flaky_issue]
      prepare_change(change, flaky_issue)
    end

    private

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def gitlab_api_helper
      @gitlab_api_helper ||= ::Keeps::Helpers::GitlabApiHelper.new
    end

    def very_flaky_issues_query_url(flakiness_label)
      format(QUERY_URL_TEMPLATE, { flakiness_label: flakiness_label })
    end

    def valid_flaky_issue?(flaky_issue)
      match = flaky_issue['description'].match(%r{\| File URL \| \[`(?<filename>[\w\/\.]+)#L(?<line_number>\d+)`\]})
      return false unless match

      filename = match[:filename]
      line_number = match[:line_number].to_i - 1

      match = flaky_issue['description'].match(%r{\| Description \| (?<description>.+) \|})
      return false unless match

      file = File.expand_path("../#{filename}", __dir__)

      unless File.exist?(file)
        puts "#{file} does not exist! Skipping"
        return false
      end

      full_file_content = File.read(file)
      file_lines = full_file_content.lines
      test_line = file_lines[line_number]

      unless test_line
        puts "#{file} doesn't have a line #{line_number}! Skipping."
        return false
      end

      unless test_line.match?(EXAMPLE_LINE_REGEX)
        puts "Line #{line_number} of #{file} doesn't match #{EXAMPLE_LINE_REGEX}! See the line content:"
        puts "```\n#{test_line}\n```"
        puts "Skipping."
        return false
      end

      true
    end

    def build_identifiers(flaky_issue)
      match = flaky_issue['description'].match(%r{\| File URL \| \[`(?<filename>[\w\/\.]+)#L(?<line_number>\d+)`\]})
      filename = match[:filename]
      line_number = match[:line_number]
      [self.class.name.demodulize, filename, line_number]
    end

    def prepare_change(change, flaky_issue)
      match = flaky_issue['description'].match(%r{\| File URL \| \[`(?<filename>[\w\/\.]+)#L(?<line_number>\d+)`\]})
      filename = match[:filename]
      line_number = match[:line_number].to_i - 1

      match = flaky_issue['description'].match(%r{\| Description \| (?<description>.+) \|})
      description = match[:description]

      file = File.expand_path("../#{filename}", __dir__)
      full_file_content = File.read(file)
      file_lines = full_file_content.lines

      puts "Quarantining #{flaky_issue['web_url']} (#{description})"

      file_lines[line_number].sub!(
        EXAMPLE_LINE_REGEX,
        "it \\k<description_and_metadata>, quarantine: '#{flaky_issue['web_url']}' do"
      )

      File.write(file, file_lines.join)

      ::Gitlab::Housekeeper::Shell.rubocop_autocorrect(file)

      construct_change(change, filename, description, flaky_issue)
    end

    def each_very_flaky_issue(url)
      gitlab_api_helper.query_api(url) do |flaky_test_issue|
        yield(flaky_test_issue)
      end
    end

    def construct_change(change, filename, description, flaky_issue)
      change.title = "Quarantine a flaky test"
      change.changed_files = [filename]
      change.description = <<~MARKDOWN
      The #{description}
      test matches one of the following conditions:
      1. has either ~"flakiness::1" or ~"flakiness::2" label set, which means the number of reported failures
      is at or above 95 percentile, indicating unusually high failure count.

      2. has ~"severity::1" label set, which means the number of reported failures
      [spiked and exceeded its daily threshold](https://gitlab.com/gitlab-org/ruby/gems/gitlab_quality-test_tooling/-/blob/c9bc10536b1f8d2d4a03c3e0b6099a40fe67ad26/lib/gitlab_quality/test_tooling/report/concerns/issue_reports.rb#L51).

      This MR quarantines the test. This is a discussion starting point to let the
      responsible group know about the flakiness so that they can take action:

      - accept the merge request and schedule the associated issue to improve the test
      - close the merge request in favor of another merge request to delete the test

      Please follow the
      [Flaky tests management process](https://handbook.gitlab.com/handbook/engineering/testing/flaky-tests/#flaky-tests-management-process)
      to help us increase `master` stability.

      Please let us know your feedback in the
      [Engineering Productivity issue tracker](https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/issues).

      Related to #{flaky_issue['web_url']}.
      MARKDOWN

      group_label = flaky_issue['labels'].grep(/group::/).first
      change.labels = [
        'maintenance::refactor',
        'test',
        'failure::flaky-test',
        'pipeline::expedited',
        'quarantine',
        'quarantine::flaky',
        group_label
      ].compact

      if change.reviewers.empty? && group_label
        group_data = groups_helper.group_for_group_label(group_label)

        change.reviewers = groups_helper.pick_reviewer(group_data, change.identifiers) if group_data
      end

      change
    end
  end
end
