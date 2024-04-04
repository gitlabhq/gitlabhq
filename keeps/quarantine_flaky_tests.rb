# frozen_string_literal: true

require 'gitlab-http'

require_relative 'helpers/groups'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. This keep will fetch any `failure::flaky-test` issues
  # with more than MINIMUM_FLAKINESS_OCCURENCES reports and quarantine these tests.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d \
  #   -k Keeps::QuarantineFlakyTests
  # ```
  class QuarantineFlakyTests < ::Gitlab::Housekeeper::Keep
    MINIMUM_FLAKINESS_OCCURENCES = 1000
    FLAKY_TEST_ISSUES_URL = "https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab/issues/?order_by=updated_at&state=opened&labels%5B%5D=test&labels%5B%5D=failure%3A%3Aflaky-test&not%5Blabels%5D%5B%5D=QA&not%5Blabel_name%5D%5B%5D=quarantine&per_page=10"
    FLAKY_TEST_ISSUE_NOTES_URL = "https://gitlab.com/api/v4/projects/gitlab-org%%2Fgitlab/issues/%<issue_iid>s/notes"
    EXAMPLE_LINE_REGEX = /([\w'",])? do$/

    def each_change
      each_very_flaky_issue do |flaky_issue|
        change = prepare_change(flaky_issue)

        yield(change) if change
      end
    end

    private

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def prepare_change(flaky_issue)
      match = flaky_issue['description'].match(%r{\| File URL \| \[`(?<filename>[\w\/\.]+)#L(?<line_number>\d+)`\]})
      return unless match

      filename = match[:filename]
      line_number = match[:line_number].to_i

      match = flaky_issue['description'].match(%r{\| Description \| (?<description>.+) \|})
      return unless match

      description = match[:description]

      file = File.expand_path("../#{filename}", __dir__)
      full_file_content = File.read(file)
      issue_url = flaky_issue['web_url']

      file_lines = full_file_content.lines
      return unless file_lines[line_number - 1].match?(EXAMPLE_LINE_REGEX)

      file_lines[line_number - 1].sub!(EXAMPLE_LINE_REGEX, "\\1, quarantine: '#{issue_url}' do")
      File.write(file, file_lines.join)

      construct_change(filename, line_number, description, flaky_issue)
    end

    def each_very_flaky_issue
      flaky_test_issues = Gitlab::HTTP.get(FLAKY_TEST_ISSUES_URL)

      flaky_test_issues_above_threshold = flaky_test_issues.select do |flaky_test_issue|
        Gitlab::HTTP.get(format(FLAKY_TEST_ISSUE_NOTES_URL, { issue_iid: flaky_test_issue['iid'] }),
          headers: { 'PRIVATE-TOKEN': ENV['HOUSEKEEPER_GITLAB_API_TOKEN'] }).find do |note|
          match = note['body'].match(/### Flakiness reports \((?<reports_count>\d+)\)/)
          next unless match

          match[:reports_count].to_i >= MINIMUM_FLAKINESS_OCCURENCES
        end
      end

      flaky_test_issues_above_threshold.map do |issue|
        yield(issue)
      end
    end

    def construct_change(filename, line_number, description, flaky_issue)
      ::Gitlab::Housekeeper::Change.new.tap do |change|
        change.title = "Quarantine a flaky test"
        change.identifiers = [self.class.name.demodulize, filename, line_number.to_s]
        change.changed_files = [filename]
        change.description = <<~MARKDOWN
        The #{description} test has been reported as flaky more then #{MINIMUM_FLAKINESS_OCCURENCES} times.

        This MR quarantines the test. This is a discussion starting point to let the responsible group know about the flakiness
        so that they can take action:

        - accept the merge request and schedule to improve the test
        - close the merge request in favor of another merge request to delete the test

        Related to #{issue_url}.
        MARKDOWN

        group_label = flaky_issue['labels'].grep(/group::/).first
        change.labels = [
          'maintenance::refactor',
          'test',
          'failure::flaky-test',
          'pipeline:expedite',
          'quarantine',
          'quarantine::flaky',
          group_label
        ].compact

        if change.reviewers.empty? && group_label
          group_data = groups_helper.group_for_group_label(group_label)

          change.reviewers = groups_helper.pick_reviewer(group_data, change.identifiers) if group_data
        end
      end
    end
  end
end
