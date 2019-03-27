# frozen_string_literal: true

module QA::Page
  module Project::Job
    class Show < QA::Page::Base
      COMPLETED_STATUSES = %w[passed failed canceled blocked skipped manual].freeze # excludes created, pending, running
      PASSED_STATUS = 'passed'.freeze

      view 'app/assets/javascripts/jobs/components/job_log.vue' do
        element :build_trace
      end

      view 'app/assets/javascripts/vue_shared/components/ci_badge_link.vue' do
        element :status_badge
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
      def output
        find_element(:build_trace).text
      end

      private

      def loaded?(wait: 60)
        wait(reload: true, max: wait, interval: 1) do
          has_element?(:build_trace, wait: 1)
        end
      end

      def completed?(timeout: 60)
        wait(reload: false, max: timeout) do
          COMPLETED_STATUSES.include?(status_badge)
        end
      end

      def status_badge
        find_element(:status_badge).text
      end
    end
  end
end
