# frozen_string_literal: true

module QA
  module Resource
    module Events
      MAX_WAIT = 60
      RAISE_ON_FAILURE = false

      EventNotFoundError = Class.new(RuntimeError)

      module Base
        def events(action: nil, target_type: nil)
          query = []
          query << "action=#{CGI.escape(action)}" if action
          query << "target_type=#{CGI.escape(target_type)}" if target_type
          path = [api_get_events]
          path << "?#{query.join('&')}" unless query.empty?
          parse_body(api_get_from(path.join.to_s))
        end

        private

        def api_get_events
          "#{api_get_path}/events"
        end

        def fetch_events
          events_returned = nil
          Support::Waiter.wait_until(max_duration: max_wait, raise_on_failure: raise_on_failure) do
            events_returned = yield
            events_returned.any?
          end

          raise EventNotFoundError, "Timed out waiting for events" unless events_returned

          events_returned
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
