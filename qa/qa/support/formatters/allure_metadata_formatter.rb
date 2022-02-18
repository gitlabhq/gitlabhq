# frozen_string_literal: true

module QA
  module Support
    module Formatters
      class AllureMetadataFormatter < ::RSpec::Core::Formatters::BaseFormatter
        ::RSpec::Core::Formatters.register(
          self,
          :example_started
        )

        # Starts example
        # @param [RSpec::Core::Notifications::ExampleNotification] example_notification
        # @return [void]
        def example_started(example_notification)
          example = example_notification.example

          add_quarantine_issue_link(example)
          add_failure_issues_link(example)
          add_ci_job_link(example)
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
          return issue_link.each { |link| example.issue('Quarantine issue', link) } if issue_link.is_a?(Array)
        end

        # Add failure issues link
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_failure_issues_link(example)
          spec_file = example.file_path.split('/').last
          example.issue(
            'Failure issues',
            "https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&state=opened&search=#{spec_file}"
          )
        end

        # Add ci job link
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_ci_job_link(example)
          return unless Runtime::Env.running_in_ci?

          example.add_link(name: "Job(#{Runtime::Env.ci_job_name})", url: Runtime::Env.ci_job_url)
        end
      end
    end
  end
end
