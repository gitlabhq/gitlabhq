# frozen_string_literal: true

module ContainerRegistry
  module Protection
    module InternalEventsTracking
      include Gitlab::InternalEventsTracking

      def track_tag_rule_creation(protection_rule)
        track_event('create_container_registry_protected_tag_rule', protection_rule)
      end

      def track_tag_rule_deletion(protection_rule)
        track_event('delete_container_registry_protected_tag_rule', protection_rule)
      end

      def track_tag_rule_update(protection_rule)
        track_event('update_container_registry_protected_tag_rule', protection_rule)
      end

      def track_repository_rule_creation(protection_rule)
        track_event('create_container_repository_protection_rule', protection_rule)
      end

      def track_repository_rule_deletion(protection_rule)
        track_event('delete_container_repository_protection_rule', protection_rule)
      end

      private

      def track_event(event_name, protection_rule)
        params = {
          project: protection_rule.project,
          namespace: protection_rule.project.namespace,
          user: current_user
        }

        if protection_rule.is_a? ContainerRegistry::Protection::TagRule
          params[:additional_properties] = { rule_type: protection_rule.type }
        end

        track_internal_event(event_name, **params)
      end
    end
  end
end
