# frozen_string_literal: true

module QA
  module Support
    module WaitForRequests
      module_function

      DEFAULT_MAX_WAIT_TIME = 60

      def wait_for_requests(skip_finished_loading_check: false)
        Waiter.wait_until(log: false) do
          finished_all_ajax_requests? && finished_all_axios_requests? && (!skip_finished_loading_check ? finished_loading?(wait: 1) : true)
        end
      end

      def finished_all_axios_requests?
        Capybara.page.evaluate_script('window.pendingRequests || 0').zero?
      end

      def finished_all_ajax_requests?
        return true if Capybara.page.evaluate_script('typeof jQuery === "undefined"')

        Capybara.page.evaluate_script('jQuery.active').zero?
      end

      def finished_loading?(wait: DEFAULT_MAX_WAIT_TIME)
        # The number of selectors should be able to be reduced after
        # migration to the new spinner is complete.
        # https://gitlab.com/groups/gitlab-org/-/epics/956
        Capybara.page.has_no_css?('.gl-spinner, .fa-spinner, .spinner', wait: wait)
      end
    end
  end
end
