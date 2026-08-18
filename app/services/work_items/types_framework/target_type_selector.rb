# frozen_string_literal: true

module WorkItems
  module TypesFramework
    # Single source of truth for resolving the destination work item type when
    # moving or cloning a work item across namespaces, mirroring the `issueMove`
    # GraphQL mutation. Types are validated against the destination namespace's
    # `WorkItems::TypesFramework::Provider#filtered_types` so tier, feature
    # flags, and namespace-level type visibility are honored everywhere.
    class TargetTypeSelector
      # source_type       - Work item type of the source item. When nil,
      #                     selection is skipped and a successful empty response
      #                     is returned.
      # target_namespace  - Group or `Namespaces::ProjectNamespace` destination.
      # type_name         - Optional name to resolve at the destination. When
      #                     nil, the source type is used.
      # same_namespace    - When true, conversion is a no-op; an explicit
      #                     `type_name` is still validated so the user gets a
      #                     clear error for unknown or disabled types.
      # action            - `'move'` or `'clone'`. Affects error wording only.
      def initialize(source_type:, target_namespace:, action:, type_name: nil, same_namespace: false)
        @source_type = source_type
        @target_namespace = target_namespace
        @type_name = type_name.to_s.strip.presence
        @same_namespace = same_namespace
        @action = action
      end

      # Returns a `ServiceResponse`. On success `payload[:type]` holds the
      # resolved type, or nil when no conversion is needed.
      def execute
        return ServiceResponse.success(payload: { type: nil }) unless source_type

        if same_namespace
          return ServiceResponse.success(payload: { type: nil }) unless type_name

          match = find_by_name(type_name)
          return ServiceResponse.error(message: invalid_type_error) unless match
          return ServiceResponse.error(message: disabled_type_error(match)) unless match.enabled?

          return ServiceResponse.success(payload: { type: nil })
        end

        match = type_name ? find_by_name(type_name) : provider.find_by_id(source_type.id)

        unless match
          message = type_name ? invalid_type_error : unavailable_source_error
          return ServiceResponse.error(message: message)
        end

        return ServiceResponse.error(message: disabled_type_error(match)) unless match.enabled?

        ServiceResponse.success(payload: { type: match })
      end

      private

      attr_reader :source_type, :target_namespace, :type_name, :same_namespace, :action

      def provider
        @provider ||= ::WorkItems::TypesFramework::Provider.new(target_namespace)
      end

      def find_by_name(name)
        provider.filtered_types.find { |type| type.name.casecmp(name) == 0 }
      end

      # `.enabled?` on top of `filtered_types` excludes archived or
      # admin-disabled types the user cannot pick at the destination.
      def available_type_names
        provider.filtered_types.select(&:enabled?).map(&:name).sort.join(', ')
      end

      def invalid_type_error
        if action == 'clone'
          format(
            s_(
              'CloneWorkItem|Unable to clone. The work item type "%{type}" is not available in the target ' \
                'namespace. Available types: %{available}.'
            ),
            type: type_name, available: available_type_names
          )
        else
          format(
            s_(
              'MoveWorkItem|Unable to move. The work item type "%{type}" is not available in the target ' \
                'namespace. Available types: %{available}.'
            ),
            type: type_name, available: available_type_names
          )
        end
      end

      def unavailable_source_error
        if action == 'clone'
          format(
            s_(
              'CloneWorkItem|Unable to clone. The source work item type "%{type}" is not available in the target ' \
                'namespace. Specify one using `[type:NAME]`. Available types: %{available}.'
            ),
            type: source_type.name, available: available_type_names
          )
        else
          format(
            s_(
              'MoveWorkItem|Unable to move. The source work item type "%{type}" is not available in the target ' \
                'namespace. Specify one using `[type:NAME]`. Available types: %{available}.'
            ),
            type: source_type.name, available: available_type_names
          )
        end
      end

      def disabled_type_error(type)
        if action == 'clone'
          format(
            s_(
              'CloneWorkItem|Unable to clone. The work item type "%{type}" is disabled in the target namespace. ' \
                'Available types: %{available}.'
            ),
            type: type.name, available: available_type_names
          )
        else
          format(
            s_(
              'MoveWorkItem|Unable to move. The work item type "%{type}" is disabled in the target namespace. ' \
                'Available types: %{available}.'
            ),
            type: type.name, available: available_type_names
          )
        end
      end
    end
  end
end
