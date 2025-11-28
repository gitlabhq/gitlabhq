# frozen_string_literal: true

require_relative 'helpers/gitlab_api_helper'

module Keeps
  class QuarantineTopFlakyTestFiles < ::Gitlab::Housekeeper::Keep
    TOP_FLAKY_TEST_FILES_PROJECT_ID = 69718754
    TOP_FLAKY_TEST_FILES_LABEL = 'automation:top-flaky-test-file'
    QUERY_URL = "https://gitlab.com/api/v4/projects/#{TOP_FLAKY_TEST_FILES_PROJECT_ID}/issues/?order_by=updated_at&state=opened&labels[]=#{TOP_FLAKY_TEST_FILES_LABEL}&per_page=20".freeze

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
      filename = withdraw_filename_from_issue(flaky_test_file_issue)

      if filename.start_with?('qa/')
        absolute_filepath = File.expand_path("../qa/#{filename}", __dir__)
        relative_file_path = "qa/#{filename}"
      else
        absolute_filepath = File.expand_path("../#{filename}", __dir__)
        relative_file_path = filename
      end

      new_file_content = update_file_content(absolute_filepath, relative_file_path, flaky_test_file_issue)
      # Return to skip MR creation if we couldn't generate new_file_content
      return unless new_file_content

      File.write(absolute_filepath, new_file_content)

      ::Gitlab::Housekeeper::Shell.rubocop_autocorrect(absolute_filepath)

      construct_change(change, relative_file_path, flaky_test_file_issue)
    end

    def construct_change(change, relative_file_path, flaky_test_file_issue)
      spec_name = relative_file_path.split('/').last
      change.title = "Quarantine flaky #{spec_name}"
      change.changed_files = [relative_file_path]
      change.description = <<~MARKDOWN
        ### Summary

        The `#{relative_file_path}` test file has been identified as one of the most flaky files in our test suite.
        Hence this auto-quarantine MR is created.

        More details about the statistics for this test file can be found in the corresponding issue: #{flaky_test_file_issue['web_url']}.

        This MR quarantines the test file. Stage group that owns this tests should review, update if needed \
        and merge this MR to quarantine the test file unless the tests can be fixed in timely manner.

        ### References

        Related to #{flaky_test_file_issue['web_url']}

        ----
      MARKDOWN
      change.labels = [
        'type::maintenance',
        'maintenance::refactor',
        'quarantine',
        'quarantine::flaky'
      ].compact
      change
    end

    def build_identifiers(flaky_test_file_issue)
      filename = withdraw_filename_from_issue(flaky_test_file_issue)
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

    def update_file_content(absolute_filepath, relative_file_path, flaky_test_file_issue)
      full_file_content = File.read(absolute_filepath)

      # As some specs declare methadata in paranthesis we need different ways
      # of matching metadata and adding quarantine tags
      match = full_file_content.match(/RSpec\.describe (?<description_and_metadata>.*?) do/m)

      if match
        new_file_content = full_file_content.gsub(match[:description_and_metadata],
          "#{match[:description_and_metadata]},\n" \
            "quarantine: { issue: '#{flaky_test_file_issue['web_url']}', type: 'flaky' }")
      else
        match = full_file_content.match(/RSpec\.describe\((?<description_and_metadata>.*?)\) do/m)

        # Return to skip MR creation if we couldn't match RSpec describe block
        unless match
          puts "ERROR: Can't find the RSpec describe block in file #{relative_file_path}"
          return
        end

        new_file_content = full_file_content.gsub(match[:description_and_metadata],
          "#{match[:description_and_metadata].rstrip},\n" \
            "quarantine: { issue: '#{flaky_test_file_issue['web_url']}', type: 'flaky' }\n")
      end

      new_file_content
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

    def withdraw_filename_from_issue(flaky_test_file_issue)
      match = match_filename(flaky_test_file_issue)
      match[:filename]
    end

    def match_filename(flaky_test_file_issue)
      # To accommodate legacy issues format we need to match in two different ways
      match = flaky_test_file_issue['description'].match(/\|\s*Spec file\s*\|\s*(?<filename>\s*.+?.rb)/m)
      match ||= flaky_test_file_issue['description'].match(/\s*\*\*File:\*\*\s*\s*`(?<filename>\s*.+?.rb)`/m)
      match
    end
  end
end
