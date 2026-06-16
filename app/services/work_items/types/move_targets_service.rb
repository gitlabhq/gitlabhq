# frozen_string_literal: true

module WorkItems
  module Types
    # Computes the work item types that a source type can become when its work
    # items are moved to a different namespace.
    #
    # For each source type, returns:
    # - `valid_target_types`: the work item types in the target namespace that
    #   the source can be moved into. This is the union of:
    #     * the destination type equivalent to the source (so the item can keep
    #       the same type when moving), and
    #     * the types the source can be converted to per
    #       `supported_conversion_types`, intersected with the target
    #       namespace's available types.
    # - `suggested_target_type`: the recommended target, picked first by gid
    #   match (covers system-defined and converted custom types), then by name
    #   match as a fallback (covers same-name custom types across namespaces).
    #   Returns `nil` when neither rule matches; the caller should let the user
    #   pick manually.
    #
    # Only types whose source supports the move action are processed; for
    # non-movable sources, both `valid_target_types` and `suggested_target_type`
    # are empty/nil so callers can surface a clear "cannot be moved" state.
    class MoveTargetsService
      include ::Gitlab::Utils::StrongMemoize

      Result = Struct.new(:source_type, :suggested_target_type, :valid_target_types, keyword_init: true)

      def initialize(current_user:, source_namespace:, target_namespace:, source_type_ids:)
        @current_user = current_user
        @source_namespace = source_namespace
        @target_namespace = target_namespace
        @source_type_ids = Array.wrap(source_type_ids).map(&:to_i).uniq
      end

      def execute
        return [] if any_invalid_namespace? || @source_type_ids.empty?

        @source_type_ids.filter_map do |source_id|
          source_type = source_provider.find_by_id(source_id)
          next unless source_type

          build_result(source_type)
        end
      end

      private

      def build_result(source_type)
        unless source_type.supports_move_action?
          return Result.new(
            source_type: source_type,
            suggested_target_type: nil,
            valid_target_types: []
          )
        end

        valid_targets = compute_valid_targets(source_type)
        suggested = compute_suggested_target(source_type, valid_targets)

        Result.new(
          source_type: source_type,
          suggested_target_type: suggested,
          valid_target_types: valid_targets
        )
      end

      # Valid targets = (source's conversion targets within target namespace)
      # plus the target-namespace type that equals the source by gid, if present.
      #
      # The second part is what allows the item to keep the same type on move,
      # since `supported_conversion_types` excludes the source's own identity.
      #
      # Group-only types (e.g. Epic) are excluded from move suggestions
      # regardless of the destination's context: the move flow targets
      # project-level work items.
      def compute_valid_targets(source_type)
        conversion_targets = source_type.supported_conversion_types(@target_namespace, @current_user)

        in_target = conversion_targets.select { |type| target_namespace_type_ids.include?(type.id) }

        same_kind = target_provider.find_by_id(source_type.id)
        in_target = ([same_kind] + in_target).uniq(&:id) if same_kind

        in_target
          .reject { |type| type.archived? || !type.enabled || type.only_for_group? }
          .sort_by { |type| type.name.downcase }
      end

      def compute_suggested_target(source_type, valid_targets)
        gid_match = valid_targets.find { |type| type.id == source_type.id }
        return gid_match if gid_match

        valid_targets.find { |type| type.name == source_type.name }
      end

      def target_namespace_type_ids
        target_provider.available_types.map(&:id).to_set
      end
      strong_memoize_attr :target_namespace_type_ids

      def source_provider
        ::WorkItems::TypesFramework::Provider.new(@source_namespace)
      end
      strong_memoize_attr :source_provider

      def target_provider
        ::WorkItems::TypesFramework::Provider.new(@target_namespace)
      end
      strong_memoize_attr :target_provider

      def any_invalid_namespace?
        @source_namespace.blank? || @target_namespace.blank?
      end
    end
  end
end
