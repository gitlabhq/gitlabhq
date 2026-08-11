# frozen_string_literal: true

module WorkItems
  module DataSync
    class BaseService < ::BaseContainerService
      include ::Services::ReturnServiceResponses

      attr_reader :work_item, :service_response, :target_namespace

      # work_item - original work item
      # target_namespace - ProjectNamespace, Group or Project. When Project is passed it is translated into
      # `Namespaces::ProjectNamespace` afterwards.
      # current_user - user performing the move/clone action
      def initialize(work_item:, target_namespace:, current_user: nil, params: {})
        # this helps reuse this service with Issue instances in legacy code, as well as WorkItem instances
        @work_item = ensure_work_item(work_item)
        @target_namespace = handle_target_namespace_type(target_namespace)

        super(container: work_item.namespace, current_user: current_user, params: params)
      end

      def execute
        verification_response = verify_work_item_action_permission
        return verification_response if verification_response.error?

        organization_response = verify_same_organization
        return organization_response if organization_response.error?

        type_response = verify_target_work_item_type
        return type_response if type_response.error?

        data_sync_action
      end

      private

      def verify_work_item_action_permission!; end

      def data_sync_action; end

      # An organization is isolated to a single cell, so a work item can never be
      # moved, cloned, or promoted into a different organization. Let nil targets
      # fall through to the subclass-specific validations.
      def verify_same_organization
        return success({}) unless prevent_cross_organization_actions?
        return success({}) if target_namespace.nil?
        return success({}) if work_item.resource_parent&.organization_id == target_namespace.organization_id

        error(
          s_('DataSync|Unable to perform this action across organizations.'),
          :unprocessable_entity
        )
      end

      def prevent_cross_organization_actions?
        Feature.enabled?(:prevent_cross_organization_work_item_actions, work_item.root_ancestor)
      end

      def ensure_work_item(work_item)
        return work_item if work_item.is_a?(WorkItem)

        WorkItem.find_by_id(work_item) if work_item.is_a?(Issue)
      end

      def handle_target_namespace_type(target_namespace)
        case target_namespace
        when Project
          target_namespace.project_namespace
        else
          target_namespace
        end
      end

      def verify_target_work_item_type
        return success({}) if skip_target_work_item_type_resolution?
        return success({}) if skip_target_work_item_type_resolution_for_epic?

        target_type_id_param = params.delete(:target_work_item_type_id)
        target_type_name_param = params.delete(:target_work_item_type_name)

        # A type _name_ comes from the `/move` and `/clone` quick actions,
        # where the user typed `[type:NAME]` and expects an actionable error
        # if that name is unknown or disabled at the destination.
        if target_type_name_param.present?
          response = ::WorkItems::TypesFramework::TargetTypeSelector.new(
            source_type: work_item.work_item_type,
            target_namespace: target_namespace,
            type_name: target_type_name_param,
            same_namespace: work_item.namespace_id == target_namespace.id,
            action: resolver_action
          ).execute

          return error(response.message, :unprocessable_entity) if response.error?

          @resolved_target_work_item_type = response.payload[:type]
          return success({})
        end

        # A type _id_ (GraphQL) or nothing (hierarchy / bulk moves, or a quick
        # action without a type) only requires the id to resolve at the
        # destination.
        target_type_id = target_type_id_param.presence unless ignore_target_work_item_type_id_param?
        target_type_id ||= work_item.work_item_type_id

        type = ::WorkItems::TypesFramework::Provider.new(target_namespace).find_by_id(target_type_id)

        return error(target_work_item_type_not_available_error_message, :unprocessable_entity) if type.nil?

        @resolved_target_work_item_type = type
        success({})
      end

      # Override to skip resolution entirely (e.g., same-namespace moves).
      def skip_target_work_item_type_resolution?
        false
      end

      # Epics are group-scoped with their own move/clone handling, so they
      # bypass the shared type selector entirely. Overridden in EE, where the
      # `epic` base type is actually reachable.
      def skip_target_work_item_type_resolution_for_epic?
        false
      end

      # Override to discard a caller-supplied `target_work_item_type_id` while
      # still verifying the source type at the destination. Used by internal
      # callers that fully control the resulting type.
      def ignore_target_work_item_type_id_param?
        false
      end

      def resolved_target_work_item_type
        @resolved_target_work_item_type || work_item.work_item_type
      end

      # Subclasses should override this to provide context-specific error messages
      def target_work_item_type_not_available_error_message
        s_("DataSync|Unable to perform action. The selected work item type is not available in the target namespace.")
      end

      # Subclasses that can reach the `target_work_item_type_name` branch above
      # must override this to control the wording of actionable error messages
      # emitted by `WorkItems::TypesFramework::TargetTypeSelector`.
      def resolver_action
        raise Gitlab::AbstractMethodError
      end
    end
  end
end

WorkItems::DataSync::BaseService.prepend_mod
