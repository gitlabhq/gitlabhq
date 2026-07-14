# frozen_string_literal: true

module Gitlab
  module WorkItems
    module Instrumentation
      class TrackingService
        extend Gitlab::InternalEventsTracking
        include Gitlab::InternalEventsTracking
        include EventActions

        # Source dimensions for events. Used in the `source` additional property
        # to segment events by origin (e.g. external coding agents vs. UI).
        SOURCE_AI_WORKFLOWS = 'ai_workflows'
        SOURCE_API = 'api'
        SOURCE_INTERNAL = 'internal'

        def self.track(event:, properties:)
          track_internal_event(event, **properties)
        end

        # Derives a source/agent dimension from the request's token scopes.
        # Returns one of: 'ai_workflows' (Duo workflows, glab, external agents using ai_workflows-scoped
        # tokens), 'api' (regular PAT/OAuth api scope or session-backed UI), or 'internal'
        # (no token in the current context, e.g. background jobs or system calls).
        def self.current_source
          token_info = ::Current.token_info
          return SOURCE_INTERNAL if token_info.nil?

          scopes = Array.wrap(token_info[:token_scopes])
          # Production normalizes scopes to symbols (see Gitlab::Auth::AuthFinders), but
          # `Current.token_info` is also set in other places, so coerce defensively.
          return SOURCE_AI_WORKFLOWS if scopes.any? { |scope| scope.to_sym == :ai_workflows }

          SOURCE_API
        end

        def initialize(work_item:, current_user:, event: nil, old_associations: nil, extra_properties: {})
          raise ArgumentError unless valid_params?(work_item, current_user, event, old_associations)

          @work_item = work_item
          @current_user = current_user
          @event = event
          @old_associations = old_associations
          @extra_properties = extra_properties || {}
        end

        def execute
          if @event
            track_internal_event(@event, **event_properties)
          else
            EventMappings
              .events_for(work_item: @work_item, old_associations: @old_associations)
              .each { |event_name| track_internal_event(event_name, **event_properties) }
          end
        end

        private

        def event_properties
          {
            user: @current_user,
            namespace: @work_item.project&.project_namespace || @work_item.namespace,
            project: @work_item.project,
            additional_properties: {
              label: @work_item.work_item_type.name,
              property: @work_item.namespace.user_role(@current_user)
            }.merge(@extra_properties)
          }
        end

        def valid_params?(work_item, current_user, event, old_associations)
          return false unless work_item.is_a?(Issue)
          return false unless current_user.is_a?(User)
          return false if event && !EventActions.valid_work_item_event?(event)
          return false if event && old_associations
          return false if !event && !old_associations

          true
        end
      end
    end
  end
end
