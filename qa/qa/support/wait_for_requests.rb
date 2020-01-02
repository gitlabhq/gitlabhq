# frozen_string_literal: true

module QA
  module Support
    module WaitForRequests
      module_function

      def wait_for_requests
        Waiter.wait do
          finished_all_ajax_requests? && finished_all_axios_requests?
        end
      end

      def finished_all_axios_requests?
        Capybara.page.evaluate_script('window.pendingRequests || 0').zero?
      end

      def finished_all_ajax_requests?
        return true if Capybara.page.evaluate_script('typeof jQuery === "undefined"')

        Capybara.page.evaluate_script('jQuery.active').zero?
      end
    end
  end
end
