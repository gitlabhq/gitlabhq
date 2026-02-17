# frozen_string_literal: true

require_relative 'helpers/gitlab_api_helper'

module Keeps
  class QuarantineTopFlakyTestFiles < ::Gitlab::Housekeeper::Keep
    TOP_FLAKY_TEST_FILES_PROJECT_ID = 69718754 # gitlab-org/quality/test-failure-issues
    TOP_FLAKY_TEST_FILES_LABELS = 'automation:top-flaky-test-file,flaky-test-reviewed'
    TOP_FLAKY_TEST_EXCLUDE_LABELS = 'flaky-test::false-positive,flakiness-class::misclassified,quarantine'
    QUERY_URL = "https://gitlab.com/api/v4/projects/#{TOP_FLAKY_TEST_FILES_PROJECT_ID}/issues/?order_by=updated_at&state=opened&labels[]=#{TOP_FLAKY_TEST_FILES_LABELS}&not[labels][]=#{TOP_FLAKY_TEST_EXCLUDE_LABELS}&per_page=20".freeze
    SHARED_EXAMPLES_INCLUSION_PATTERNS = %w[
      it_behaves_like
      include_examples
    ].freeze

    def each_identified_change
      each_top_flaky_test_file(QUERY_URL) do |flaky_test_file_issue|
        next unless valid_flaky_issue?(flaky_test_file_issue)

        change = ::Gitlab::Housekeeper::Change.new
        change.context = { flaky_test_file_issue: flaky_test_file_issue }
        change.identifiers = build_identifiers(flaky_test_file_issue)
        yield(change)
      end
    end

    def make_change!(change)
      flaky_test_file_issue = change.context[:flaky_test_file_issue]
      prepare_change(change, flaky_test_file_issue)
    end

    private

    def prepare_change(change, flaky_test_file_issue)
      filename = extract_filename_from_issue(flaky_test_file_issue)
      failing_tests = flaky_test_file_issue['description'].scan(/#{filename}:\d+/)

      return if failing_tests.empty?

      # Handle cases when tests are in qa/qa directory
      failing_tests = failing_tests.map { |test| test.start_with?('qa/') ? "qa/#{test}" : test }

      if filename.start_with?('qa/')
        absolute_filepath = File.expand_path("../qa/#{filename}", __dir__)
        relative_file_path = "qa/#{filename}"
      else
        absolute_filepath = File.expand_path("../#{filename}", __dir__)
        relative_file_path = filename
      end

      new_file_content = update_file_content_per_test(absolute_filepath, flaky_test_file_issue, failing_tests)

      # Return to skip MR creation if we couldn't generate new_file_content
      return unless new_file_content

      File.write(absolute_filepath, new_file_content)

      ::Gitlab::Housekeeper::Shell.rubocop_autocorrect(absolute_filepath)

      construct_change(change, relative_file_path, flaky_test_file_issue)
    end

    def construct_change(change, relative_file_path, flaky_test_file_issue)
      spec_name = relative_file_path.split('/').last
      owner_product_group = extract_testfile_owner_from_issue(flaky_test_file_issue)
      owner_product_group.tr!('_', ' ') if owner_product_group
      owner_product_group_label = owner_product_group ? "group::#{owner_product_group}" : nil
      change.title = "Quarantine flaky #{spec_name}"
      change.changed_files = [relative_file_path]
      change.description = <<~MARKDOWN
        ### Summary

        The `#{relative_file_path}` test file has been identified as a **top pipeline-blocking flaky test**, determined using test execution metrics. This auto-quarantine MR quarantines affected tests in the test file to improve pipeline stability.

        Visit the handbook page for more details: [Reporting of Top Flaky Test Files](https://handbook.gitlab.com/handbook/engineering/testing/flaky-tests/#reporting-of-top-flaky-test-files)

        More details about the statistics for this test file can be found in the corresponding issue: #{flaky_test_file_issue['web_url']}.

        The product group that owns these tests should:
        1. Review the quarantine changes in this MR
        2. Either **merge this MR** to quarantine the tests, OR
        3. **Fix the underlying flakiness** in line with [Flaky tests - Urgency Tiers and Response Timelines](https://handbook.gitlab.com/handbook/engineering/testing/flaky-tests/#urgency-tiers-and-response-timelines)

        ### References

        Related to #{flaky_test_file_issue['web_url']}

        ----
      MARKDOWN
      change.labels = [
        'type::maintenance',
        'maintenance::refactor',
        'quarantine',
        'quarantine::flaky',
        owner_product_group_label
      ].compact
      change
    end

    def build_identifiers(flaky_test_file_issue)
      filename = extract_filename_from_issue(flaky_test_file_issue)
      [self.class.name.demodulize, filename]
    end

    def each_top_flaky_test_file(url)
      gitlab_api_helper.query_api(url) do |flaky_test_file_issue|
        yield(flaky_test_file_issue)
      end
    end

    def gitlab_api_helper
      @gitlab_api_helper ||= ::Keeps::Helpers::GitlabApiHelper.new
    end

    def update_file_content_per_test(absolute_filepath, flaky_test_file_issue, failing_tests)
      full_file_content = File.read(absolute_filepath)
      file_lines = full_file_content.lines

      failing_tests.each do |test|
        puts "INFO: Processing test: #{test}"

        test_line = test.split(':').last.to_i - 1 # we need -1 as we use this as index in file_lines array

        # Skip test if identified test_line is invalid
        if test_line >= file_lines.size || test_line < 0
          puts "WARN: Invalid line number #{test_line + 1} for file. Skipping test #{test}"
          next
        end

        if SHARED_EXAMPLES_INCLUSION_PATTERNS.any? { |pattern| file_lines[test_line].include?(pattern) }
          file_lines[test_line] = add_quarantine_for_shared_example(file_lines, test_line, flaky_test_file_issue)
        elsif file_lines[test_line].strip.start_with?("it {")
          file_lines[test_line] = add_quarantine_for_it_example_without_name(
            file_lines,
            test_line,
            flaky_test_file_issue
          )
        elsif file_lines[test_line].strip.start_with?("it")
          line = find_quarantine_line_for_it_example(file_lines, test_line)

          next unless line

          file_lines[line] = add_quarantine_for_it_example(file_lines, line, flaky_test_file_issue)
        else
          puts "WARN: Can not auto-quarantine #{test}"
          next
        end

        puts "INFO: File updated to quarantine #{test}"
      end

      updated_file_content = file_lines.join

      return if full_file_content == updated_file_content

      updated_file_content
    end

    def add_quarantine_for_shared_example(file_lines, line, flaky_test_file_issue)
      # To avoid rubocop exception RSpec/RepeatedExampleGroupBody
      # use line number and date in quarantine context name to make it uniq within test file
      file_lines[line].gsub(
        /(it_behaves_like|include_examples) .+/,
        "context 'with quarantine id #{line}-#{Date.current.iso8601}',\n" \
          "quarantine: { issue: '#{flaky_test_file_issue['web_url']}', type: 'flaky' } do\n  \\0\nend"
      )
    end

    def add_quarantine_for_it_example(file_lines, line, flaky_test_file_issue)
      file_lines[line].gsub(
        " do\n",
        ",\nquarantine: { issue: '#{flaky_test_file_issue['web_url']}', type: 'flaky' } do\n"
      )
    end

    def add_quarantine_for_it_example_without_name(file_lines, line, flaky_test_file_issue)
      file_lines[line].gsub(
        /it \{ (.+) \}/,
        "it quarantine: { issue: '#{flaky_test_file_issue['web_url']}', type: 'flaky' } do\n  \\1\nend"
      )
    end

    def find_quarantine_line_for_it_example(file_lines, test_line, check_lines: 5)
      check_lines.times do
        return if file_lines[test_line].include?("quarantine")
        return test_line if file_lines[test_line].ends_with?("do\n")

        test_line += 1
      end
      puts "WARN: Can not find line to add quarantine"
      nil
    end

    def valid_flaky_issue?(flaky_test_file_issue)
      match = match_filename(flaky_test_file_issue)
      return false unless match

      filename = match[:filename]

      absolute_filepath = if filename.start_with?('qa/')
                            File.expand_path("../qa/#{filename}", __dir__)
                          else
                            File.expand_path("../#{filename}", __dir__)
                          end

      unless File.exist?(absolute_filepath)
        puts "#{absolute_filepath} does not exist! Skipping"
        return false
      end

      true
    end

    def extract_filename_from_issue(flaky_test_file_issue)
      match = match_filename(flaky_test_file_issue)
      match[:filename]
    end

    def match_filename(flaky_test_file_issue)
      # To accommodate legacy issues format we need to match in two different ways
      match = flaky_test_file_issue['description'].match(/\|\s*Spec file\s*\|\s*(?<filename>\s*.+?.rb)/m)
      match ||= flaky_test_file_issue['description'].match(/\s*\*\*File:\*\*\s*\s*`(?<filename>\s*.+?.rb)`/m)
      match
    end

    def extract_testfile_owner_from_issue(flaky_test_file_issue)
      match = flaky_test_file_issue['description'].match(/\s*\*\*Product Group:\*\*\s*\s*(?<product_group>\s*.+?)\n/m)
      match&.[](:product_group)
    end
  end
end
