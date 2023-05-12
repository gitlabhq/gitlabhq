# frozen_string_literal: true

module Gitlab
  module Graphql
    module CallsGitaly
      # Check if any `calls_gitaly: true` declarations need to be added
      #
      # See BaseField: this extension is not applied if the field does not
      # need it (i.e. it has a constant complexity or knows that it calls
      # gitaly)
      class FieldExtension < ::GraphQL::Schema::FieldExtension
        include Laziness

        def resolve(object:, arguments:, **rest)
          yield(object, arguments, [current_gitaly_call_count, accounted_for])
        end

        def after_resolve(value:, memo:, **rest)
          (value, count) = value_with_count(value, memo)
          calls_gitaly_check(count)
          accounted_for(count)

          value
        end

        private

        # Resolutions are not nested nicely (due to laziness), so we have to
        # know not just how many calls were made before resolution started, but
        # also how many were accounted for by fields with the correct settings
        # in between.
        #
        # e.g. the following is not just plausible, but common:
        #
        #   enter A.user (lazy)
        #   enter A.x
        #   leave A.x
        #   enter A.calls_gitaly
        #   leave A.calls_gitaly (accounts for 1 call)
        #   leave A.user
        #
        # In this circumstance we need to mark the calls made by A.calls_gitaly
        # as accounted for, even though they were made after we yielded
        # in A.user
        def value_with_count(value, (previous_count, previous_accounted_for))
          newly_accounted_for = accounted_for - previous_accounted_for
          value = force(value)
          count = [current_gitaly_call_count - (previous_count + newly_accounted_for), 0].max

          [value, count]
        end

        def current_gitaly_call_count
          Gitlab::GitalyClient.get_request_count || 0
        end

        def calls_gitaly_check(calls)
          return if calls < 1 || field.may_call_gitaly?

          error = RuntimeError.new(<<~ERROR)
            #{field_name} unexpectedly calls Gitaly!

            Please either specify a constant complexity or add `calls_gitaly: true`
            to the field declaration
          ERROR
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
        end

        def accounted_for(count = nil)
          return 0 unless Gitlab::SafeRequestStore.active?

          Gitlab::SafeRequestStore["graphql_gitaly_accounted_for"] ||= 0

          if count.nil?
            Gitlab::SafeRequestStore["graphql_gitaly_accounted_for"]
          else
            Gitlab::SafeRequestStore["graphql_gitaly_accounted_for"] += count
          end
        end

        def field_name
          "#{field.owner.graphql_name}.#{field.graphql_name}"
        end
      end
    end
  end
end
