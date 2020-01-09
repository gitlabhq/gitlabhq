# frozen_string_literal: true

module QA
  module Resource
    module Events
      MAX_WAIT = 10
      RAISE_ON_FAILURE = true

      EventNotFoundError = Class.new(RuntimeError)

      module Base
        def events(action: nil)
          path = [api_get_events]
          path << "?action=#{CGI.escape(action)}" if action
          parse_body(api_get_from("#{path.join}"))
        end

        private

        def api_get_events
          "#{api_get_path}/events"
        end

        def wait_for_event
          event_found = Support::Waiter.wait_until(max_duration: max_wait, raise_on_failure: raise_on_failure) do
            yield
          end

          raise EventNotFoundError, "Timed out waiting for event" unless event_found
        end

        def max_wait
          MAX_WAIT
        end

        def raise_on_failure
          RAISE_ON_FAILURE
        end
      end
    end
  end
end
