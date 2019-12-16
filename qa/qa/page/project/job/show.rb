# frozen_string_literal: true

module QA::Page
  module Project::Job
    class Show < QA::Page::Base
      include Component::CiBadgeLink

      view 'app/assets/javascripts/jobs/components/job_log.vue' do
        element :build_trace
      end

      view 'app/assets/javascripts/jobs/components/stages_dropdown.vue' do
        element :pipeline_path
      end

      def successful?(timeout: 60)
        raise "Timed out waiting for the build trace to load" unless loaded?
        raise "Timed out waiting for the status to be a valid completed state" unless completed?(timeout: timeout)

        status_badge == PASSED_STATUS
      end

      # Reminder: You may wish to wait for a particular job status before checking output
      def output(wait: 5)
        result = ''

        wait(reload: false, max: wait, interval: 1) do
          result = find_element(:build_trace).text

          result.include?('Job')
        end

        result
      end

      private

      def loaded?(wait: 60)
        wait(reload: true, max: wait, interval: 1) do
          has_element?(:build_trace, wait: 1)
        end
      end
    end
  end
end
