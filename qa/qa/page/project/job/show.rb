module QA::Page
  module Project::Job
    class Show < QA::Page::Base
      COMPLETED_STATUSES = %w[passed failed canceled blocked skipped manual].freeze # excludes created, pending, running
      PASSED_STATUS = 'passed'.freeze

      view 'app/assets/javascripts/jobs/components/job_app.vue' do
        element :loading_animation
      end

      view 'app/assets/javascripts/jobs/components/job_log.vue' do
        element :build_trace
      end

      view 'app/assets/javascripts/vue_shared/components/ci_badge_link.vue' do
        element :status_badge
      end

      view 'app/assets/javascripts/jobs/components/stages_dropdown.vue' do
        element :pipeline_path
      end

      def loaded?(wait: 60)
        has_element?(:build_trace, wait: wait)
      end

      # Reminder: You should check #loaded? first
      def completed?(timeout: 60)
        wait(reload: false, max: timeout) do
          COMPLETED_STATUSES.include?(status_badge)
        end
      end

      # Reminder: You should check #completed? and #loaded? first
      def successful?
        status_badge == PASSED_STATUS
      end

      def trace_loading?
        has_element?(:loading_animation)
      end

      # Reminder: You may wish to wait for a particular job status before checking output
      def output
        find_element(:build_trace).text
      end

      private

      def status_badge
        find_element(:status_badge).text
      end
    end
  end
end
