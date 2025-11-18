# frozen_string_literal: true

module QA
  module Support
    module WaitForRequests
      module_function

      DEFAULT_MAX_WAIT_TIME = 60

      def wait_for_requests(skip_spinner_check: true, spinner_wait: 1)
        if skip_spinner_check
          only_wait_for_ajax_requests
        else
          wait_for_ajax_requests_and_spinner(spinner_wait)
        end
      end

      def only_wait_for_ajax_requests
        Waiter.wait_until(log: false) { finished_all_ajax_requests? }
      rescue Repeater::WaitExceededError
        raise $!, "Page did not fully load after #{DEFAULT_MAX_WAIT_TIME} seconds due to pending AJAX requests"
      end

      def wait_for_ajax_requests_and_spinner(spinner_wait)
        ajax_complete = false
        spinner_complete = false
        Waiter.wait_until(log: false) do
          ajax_complete = finished_all_ajax_requests?
          spinner_complete = spinner_cleared?(wait: spinner_wait)
          ajax_complete && spinner_complete
        end
      rescue Repeater::WaitExceededError
        failure_reason = determine_failure_reason(ajax_complete, spinner_complete)
        raise $!, "Page did not fully load: #{failure_reason}"
      end

      def determine_failure_reason(ajax_complete, spinner_complete)
        if !ajax_complete && !spinner_complete
          "AJAX requests pending and spinner is still visible"
        elsif !ajax_complete && spinner_complete
          "AJAX requests pending (spinner check passed)"
        elsif !spinner_complete && ajax_complete
          "Spinner still visible (AJAX requests completed)"
        end
      end

      def finished_all_ajax_requests?
        requests = %w[window.pendingRequests window.pendingApolloRequests window.pendingRailsUJSRequests 0]

        if Runtime::Env.can_intercept?
          requests.unshift('(window.Interceptor && window.Interceptor.activeFetchRequests)')
        end

        script = requests.join(' || ')
        Capybara.page.evaluate_script(script).to_i == 0
      end

      def spinner_exists?
        Capybara.page.has_css?('.gl-spinner', wait: 2)
      end

      def spinner_cleared?(wait: DEFAULT_MAX_WAIT_TIME)
        Capybara.page.has_no_css?('.gl-spinner', wait: wait)
      rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
        QA::Runtime::Logger.error(".gl-spinner reference has become stale: #{e}")
        true
      end
    end
  end
end
