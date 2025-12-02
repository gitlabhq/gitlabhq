# frozen_string_literal: true

module ContainerRegistry
  module Protection
    module InternalEventsTracking
      include Gitlab::InternalEventsTracking

      def track_tag_rule_creation(protection_rule)
        track_protection_rule_event(
          'create_container_registry_protected_tag_rule',
          protection_rule,
          { rule_type: rule_type_for_tag_rule(protection_rule) }
        )
      end

      # Track deletion of container registry protection tag rules
      def track_tag_rule_deletion(protection_rule)
        track_protection_rule_event(
          'delete_container_registry_protected_tag_rule',
          protection_rule,
          { rule_type: rule_type_for_tag_rule(protection_rule) }
        )
      end

      # Track update of container registry protection tag rules
      def track_tag_rule_update(protection_rule)
        track_protection_rule_event(
          'update_container_registry_protected_tag_rule',
          protection_rule,
          { rule_type: rule_type_for_tag_rule(protection_rule) }
        )
      end

      private

      # Generic method to track protection rule events
      def track_protection_rule_event(event_name, protection_rule, additional_properties = {})
        params = {
          project: protection_rule.project,
          namespace: protection_rule.project.namespace,
          user: current_user
        }

        params[:additional_properties] = additional_properties unless additional_properties.empty?

        track_internal_event(event_name, **params)
      end

      # Determine rule type for tag rules (mutable by default, can be overridden in EE)
      def rule_type_for_tag_rule(protection_rule)
        protection_rule.type
      end
    end
  end
end
