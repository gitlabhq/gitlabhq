# frozen_string_literal: true

module WorkItems
  module TypesFramework
    # NamespacedType is a wrapper around SystemDefined::Type and Custom::Type that adds
    # namespace-specific configuration and state. This is the type that Provider returns
    # for all type lookups.
    #
    # Configuration responsibilities:
    # - Namespace-specific state (enabled, context flags) belongs here
    # - Static type configuration belongs in SystemDefined::Type or Custom::Type
    #
    # We use a delegator rather than adding attributes directly to the type because
    # SystemDefined::Type instances are singletons backed by FixedItemsModel - they
    # share the same object_id across all callers. Mutating them would leak state
    # between requests.
    #
    # The identity method overrides (class, is_a?, instance_of?) ensure that
    # FixedItemsModel's equality check (`other.instance_of?(self.class)`) sees
    # the wrapped type's class, keeping NamespacedType transparent to code that
    # compares types by identity.
    class NamespacedType < SimpleDelegator
      def initialize(type, enabled: true, is_a_group: false, tasks_on_boards: false, namespace: nil)
        super(type)
        @enabled = enabled
        @is_a_group = is_a_group
        @tasks_on_boards = tasks_on_boards
        @namespace = namespace
      end

      def class
        delegation_source.class
      end

      def is_a?(klass)
        delegation_source.is_a?(klass) || super
      end

      alias_method :kind_of?, :is_a?

      def instance_of?(klass)
        delegation_source.instance_of?(klass)
      end

      def filterable_list_view?
        return false unless available_for_filtering?

        if is_a_group
          delegation_source.filterable_list_view?
        else
          !delegation_source.only_for_group? && delegation_source.filterable_list_view?
        end
      end

      def filterable_board_view?
        return false unless available_for_filtering?
        return true if delegation_source.task? && tasks_on_boards

        delegation_source.filterable_board_view?
      end

      def can_user_create_items?
        enabled? && delegation_source.creatable?
      end

      def enabled_by_default_for_new_namespaces?
        true
      end

      def enabled?
        enabled && !delegation_source.archived? && visible_in_context?
      end

      attr_reader :enabled

      private

      attr_writer :enabled
      attr_accessor :is_a_group, :tasks_on_boards, :namespace

      # Archived types are unavailable everywhere; disabled types are unavailable
      # only at project level (a type disabled at the group may still be enabled
      # in descendant projects, and group-level lists aggregate from descendants).
      def available_for_filtering?
        return false if delegation_source.archived?
        return false if !is_a_group && !enabled

        true
      end

      def visible_in_context?
        if is_a_group
          delegation_source.only_for_group?
        else
          !delegation_source.only_for_group?
        end
      end

      def delegation_source
        __getobj__
      end
    end
  end
end

WorkItems::TypesFramework::NamespacedType.prepend_mod
