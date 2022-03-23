# frozen_string_literal: true

module QA
  module Support
    module WaitForRequests
      module_function

      DEFAULT_MAX_WAIT_TIME = 60

      def wait_for_requests(skip_finished_loading_check: false, skip_resp_code_check: false)
        # We have tests that use 404 pages, allow them to skip this check
        unless skip_resp_code_check
          QA::Support::PageErrorChecker.check_page_for_error_code(Capybara.page)
        end

        Waiter.wait_until(log: false) do
          finished_all_ajax_requests? && (!skip_finished_loading_check ? finished_loading?(wait: 1) : true)
        end
        QA::Support::PageErrorChecker.log_request_errors(Capybara.page) if QA::Runtime::Env.can_intercept?
      rescue Repeater::WaitExceededError
        raise $!, 'Page did not fully load. This could be due to an unending async request or loading icon.'
      end

      def finished_all_ajax_requests?
        requests = %w[window.pendingRequests window.pendingRailsUJSRequests 0]
        requests.unshift('(window.Interceptor && window.Interceptor.activeFetchRequests)') if Runtime::Env.can_intercept?
        script = requests.join(' || ')
        Capybara.page.evaluate_script(script).zero? # rubocop:disable Style/NumericPredicate
      end

      def finished_loading?(wait: DEFAULT_MAX_WAIT_TIME)
        # The number of selectors should be able to be reduced after
        # migration to the new spinner is complete.
        # https://gitlab.com/groups/gitlab-org/-/epics/956
        # retry_on_exception added here due to `StaleElementReferenceError`. See: https://gitlab.com/gitlab-org/gitlab/-/issues/232485
        Support::Retrier.retry_on_exception do
          Capybara.page.has_no_css?('.gl-spinner', wait: wait)
        end
      end
    end
  end
end
