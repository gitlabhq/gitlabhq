# frozen_string_literal: true

module Gitlab
  module InternalEvents
    # Declarative helper for Internal Events tracking in services.
    #
    # Usage:
    #
    #   class MyService
    #     include Gitlab::InternalEvents::ServiceTracking
    #
    #     track_internal_event 'thing_created', on: :success
    #     track_internal_event 'thing_creation_failed', on: :error
    #
    #     def execute
    #       # ... returns ServiceResponse or ActiveRecord model
    #     end
    #
    #     private
    #
    #     # Optional overrides - defaults extract project/namespace from
    #     # Hash payload values automatically (e.g. `{ board: board }`
    #     # will find `board.project` and `board.group`).
    #     def tracking_project_source(result)
    #       result&.payload&.dig(:board)&.project
    #     end
    #
    #     def tracking_namespace_source(result)
    #       result&.payload&.dig(:board)&.group
    #     end
    #   end
    #
    # The `on:` option accepts:
    #   :success  - fires when the result is a successful ServiceResponse, a
    #               persisted ActiveRecord object, or any other truthy value.
    #   :error    - fires when the result is an error ServiceResponse, a
    #               non-persisted ActiveRecord object, or a falsy value.
    #   :always   - fires unconditionally after execute.
    #   Proc      - custom callable: `on: ->(result) { result.valid? }`
    #   Symbol    - instance method name: `on: :custom_check?`
    #
    # The `conditions:` option accepts a Symbol (method name), Proc, or Array of
    # either. All conditions must be truthy for the event to fire.
    #
    # The `additional_properties:` option accepts a Hash or a Proc that receives
    # the tracking result and returns a Hash.
    module ServiceTracking
      extend ActiveSupport::Concern

      included do
        # Prepend the wrapper module so that `execute` is intercepted.
        prepend ExecuteWrapper
      end

      # Wraps `execute` to capture the result and fire tracking calls.
      module ExecuteWrapper
        def execute(...)
          result = super
          self.class.tracked_events.each { |config| fire_tracking_event(config, result) }
          result
        end
      end

      class_methods do
        # Registered event configurations for this class and its ancestors.
        def tracked_events
          @tracked_events ||= []

          if superclass.respond_to?(:tracked_events)
            superclass.tracked_events + @tracked_events
          else
            @tracked_events
          end
        end

        def track_internal_event(event_name, on: :success, conditions: nil, additional_properties: {})
          @tracked_events ||= []
          @tracked_events << {
            event_name: event_name,
            on: on,
            conditions: Array.wrap(conditions),
            additional_properties: additional_properties
          }
        end
      end

      private

      def fire_tracking_event(config, result)
        return unless should_track?(config[:on], result)
        return unless conditions_met?(config[:conditions])

        props = resolve_additional_properties(config[:additional_properties], result)

        Gitlab::InternalEvents.track_event(
          config[:event_name],
          category: self.class.name,
          user: tracking_user_source,
          project: tracking_project_source(result),
          namespace: tracking_namespace_source(result),
          additional_properties: props
        )
      end

      def should_track?(on_option, result)
        case on_option
        when :always
          true
        when :success
          success_result?(result)
        when :error
          !success_result?(result)
        when Symbol
          send(on_option) # rubocop:disable GitlabSecurity/PublicSend -- method name comes from class-level DSL
        when Proc
          on_option.call(result)
        else
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
            ArgumentError.new(
              "Invalid `on:` value for #{self.class.name}: #{on_option.inspect}. " \
                "Expected :always, :success, :error, a Symbol method name, or a Proc."
            )
          )
          false
        end
      end

      def success_result?(result)
        if result.is_a?(ServiceResponse)
          result.success?
        elsif result.respond_to?(:persisted?)
          result.persisted?
        else
          result.present?
        end
      end

      def conditions_met?(conditions)
        conditions.all? do |condition|
          case condition
          when Symbol
            send(condition) # rubocop:disable GitlabSecurity/PublicSend -- method name comes from class-level DSL
          when Proc
            condition.call(self)
          else
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
              ArgumentError.new(
                "Invalid `conditions:` entry for #{self.class.name}: #{condition.inspect}. " \
                  "Expected a Symbol method name or a Proc."
              )
            )
            false
          end
        end
      end

      def resolve_additional_properties(additional_properties, result)
        if additional_properties.respond_to?(:call)
          additional_properties.call(result) || {}
        elsif additional_properties.is_a?(Hash)
          additional_properties
        else
          {}
        end
      end

      # Default implementations - services may override these for custom
      # extraction logic. The defaults handle the common case where execute
      # returns a ServiceResponse with a Hash payload (e.g. `{ board: board }`).
      # They iterate the payload values looking for the first object that
      # responds to the relevant method.

      def tracking_user_source
        current_user if respond_to?(:current_user, true)
      end

      def tracking_project_source(result)
        extract_from_payload(result) { |v| v.project if v.respond_to?(:project) }
      end

      def tracking_namespace_source(result)
        extract_from_payload(result) { |v| v.namespace if v.respond_to?(:namespace) } ||
          extract_from_payload(result) { |v| v.group if v.respond_to?(:group) }
      end

      def extract_from_payload(result)
        values = if result.is_a?(ServiceResponse)
                   payload = result.payload
                   payload.is_a?(Hash) ? payload.values : []
                 else
                   [result]
                 end

        values.each do |value|
          found = yield(value)
          return found if found
        end

        nil
      end
    end
  end
end
