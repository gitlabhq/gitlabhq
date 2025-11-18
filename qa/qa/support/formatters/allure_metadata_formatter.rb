# frozen_string_literal: true

module QA
  module Support
    module Formatters
      # RSpec formatter to enhance metadata present in allure report
      # Following additional data is added:
      #   * quarantine issue links
      #   * failure issues search link
      #   * ci job link
      #   * devops stage and group as epic and feature behavior tags
      #
      class AllureMetadataFormatter < ::RSpec::Core::Formatters::BaseFormatter
        ISSUE_PROJECT = "gitlab-org/quality/e2e-test-issues"

        ::RSpec::Core::Formatters.register(self, :example_finished)

        # Finished example
        # Add additional metadata to report
        #
        # @param [RSpec::Core::Notifications::ExampleNotification] example_notification
        # @return [void]
        def example_finished(example_notification)
          example = example_notification.example

          add_quarantine_issue_link(example)
          add_failure_issues_link(example, example_notification)
          add_ci_job_link(example)
          set_behavior_categories(example)
        end

        private

        # Add quarantine issue links
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_quarantine_issue_link(example)
          issue_link = example.metadata.dig(:quarantine, :issue)

          return unless issue_link
          return example.issue('Quarantine issue', issue_link) if issue_link.is_a?(String)

          issue_link.each { |link| example.issue('Quarantine issue', link) } if issue_link.is_a?(Array)
        rescue StandardError => e
          log(:error, "Failed to add quarantine issue link for example '#{example.description}', error: #{e}")
        end

        # Add failure issues link
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_failure_issues_link(example, example_notification)
          return unless example.execution_result.status == :failed

          search_parameters = {
            sort: 'updated_desc',
            scope: 'all',
            state: 'opened'
          }.map { |key, value| "#{key}=#{value}" }.join('&')

          exception_message = example.exception.message || ""
          message_lines = strip_ansi_codes(example_notification.message_lines) || []
          exception_message_lines = message_lines.first(20)
          search_terms = {
            test_file_path: example.file_path.gsub('./qa/specs/features/', '').to_s,
            exception_message: exception_message_lines.empty? ? exception_message : exception_message_lines.join("\n")
          }.map { |_, value| "search=#{ERB::Util.url_encode(value)}" }.join('&')

          search_url = "https://gitlab.com/#{ISSUE_PROJECT}/-/issues?#{search_parameters}&#{search_terms}"
          example.issue('Failure issues', search_url)
        rescue StandardError => e
          log(:error, "Failed to add failure issue link for example '#{example.description}', error: #{e}")
        end

        def strip_ansi_codes(strings)
          modified = Array(strings).map { |string| string.dup.gsub(/\x1b\[{1,2}[0-9;:?]*m/m, '') }
          modified.size == 1 ? modified[0] : modified
        end

        # Add ci job link
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_ci_job_link(example)
          return unless Runtime::Env.running_in_ci?

          example.add_link(name: "Job(#{Runtime::Env.ci_job_name})", url: Runtime::Env.ci_job_url)
        rescue StandardError => e
          log(:error, "Failed to add ci job link for example '#{example.description}', error: #{e}")
        end

        # Add behavior categories to report
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def set_behavior_categories(example)
          file_path = example.file_path.gsub('./qa/specs/features', '')
          devops_stage = file_path.match(%r{\d{1,2}_(\w+)/})&.captures&.first

          feature_category = example.metadata[:feature_category]
          product_group = example.metadata[:product_group]

          example.epic(devops_stage) if devops_stage
          example.feature(feature_category) if feature_category
          example.feature(product_group) if product_group && feature_category.nil?
        end

        # Print log message
        #
        # @param [Symbol] level
        # @param [String] message
        # @return [void]
        def log(level, message)
          QA::Runtime::Logger.public_send(level, "[Allure]: #{message}")
        end
      end
    end
  end
end
