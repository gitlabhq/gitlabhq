module QA::Page
  module Project::Job
    class Show < QA::Page::Base
      COMPLETED_STATUSES = %w[passed failed canceled blocked skipped manual].freeze # excludes created, pending, running
      PASSED_STATUS = 'passed'.freeze

      view 'app/views/shared/builds/_build_output.html.haml' do
        element :build_output, '.js-build-output' # rubocop:disable QA/ElementWithPattern
        element :loading_animation, '.js-build-refresh' # rubocop:disable QA/ElementWithPattern
      end

      view 'app/assets/javascripts/vue_shared/components/ci_badge_link.vue' do
        element :status_badge, 'ci-status' # rubocop:disable QA/ElementWithPattern
      end

      def completed?
        COMPLETED_STATUSES.include? find('.ci-status').text
      end

      def passed?
        find('.ci-status').text == PASSED_STATUS
      end

      def trace_loading?
        has_css?('.js-build-refresh')
      end

      # Reminder: You may wish to wait for a particular job status before checking output
      def output
        find('.js-build-output').text
      end
    end
  end
end
