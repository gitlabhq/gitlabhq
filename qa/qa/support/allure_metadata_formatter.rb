# frozen_string_literal: true

require 'rspec/core'
require "rspec/core/formatters/base_formatter"

module QA
  module Support
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

        testcase = example.metadata[:testcase]
        example.tms('Testcase', testcase) if testcase

        quarantine_issue = example.metadata.dig(:quarantine, :issue)
        example.issue('Quarantine issue', quarantine_issue) if quarantine_issue

        spec_file = example.file_path.split('/').last
        example.issue(
          'Failure issues',
          "https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&state=opened&search=#{spec_file}"
        )
        return unless Runtime::Env.running_in_ci?

        example.add_link(name: "Job(#{Runtime::Env.ci_job_name})", url: Runtime::Env.ci_job_url)
      end
    end
  end
end
