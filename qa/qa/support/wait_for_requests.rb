# frozen_string_literal: true

module QA
  module Support
    module WaitForRequests
      module_function

      DEFAULT_MAX_WAIT_TIME = 60

      def wait_for_requests(skip_finished_loading_check: false, skip_resp_code_check: false)
        Waiter.wait_until(log: false) do
          finished_all_ajax_requests? && (!skip_finished_loading_check ? finished_loading?(wait: 1) : true)
        end
      rescue Repeater::WaitExceededError
        raise $!, 'Page did not fully load. This could be due to an unending async request or loading icon.'
      end

      def finished_all_ajax_requests?
        requests = %w[window.pendingRequests window.pendingApolloRequests window.pendingRailsUJSRequests 0]

        if Runtime::Env.can_intercept?
          requests.unshift('(window.Interceptor && window.Interceptor.activeFetchRequests)')
        end

        script = requests.join(' || ')
        Capybara.page.evaluate_script(script).zero? # rubocop:disable Style/NumericPredicate
      end

      def spinner_exists?
        Capybara.page.has_css?('.gl-spinner', wait: 2)
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
