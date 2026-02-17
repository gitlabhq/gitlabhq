# frozen_string_literal: true

module WorkItems
  module TypesFramework
    # This is the single source of truth to fetch work item types.
    #
    # In the future namespaces can use system-defined and custom work item types.
    # This class aims to abstract that fetching logic away so application code doesn't need to care
    # about the composition of types of a given namespace.
    #
    # For now we use this interface to fetch types from the database to make the switchover easier.
    # We already use the final methods from the POC, but will change the implementation using caching etc.
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214894
    class Provider
      include Gitlab::Utils::StrongMemoize

      class << self
        def unfiltered_base_types
          WorkItems::Type.base_types.keys
        end
      end

      def initialize(namespace = nil)
        # Always try to pass the current namespace or subtypes(Group, Project::Namepsace) and not the root ancestor.
        #
        # We will use it to fetch custom types and apply the TypesFilter.
        #
        # For custom types we need to either
        # 1. fetch types by organization_id of the namespace for Self-Managed
        # 2. fetch types by the root group for Saas
        #
        # See https://gitlab.com/groups/gitlab-org/-/work_items/20291
        @namespace = namespace
      end

      attr_reader :namespace

      def fetch_work_item_type(work_item_type)
        work_item_type_id = work_item_type.respond_to?(:id) ? work_item_type.id : work_item_type
        find_by_id(work_item_type_id)
      end

      # This list of types will exclude custom types because they're based on top of the `issue` base type.
      # We use the base types in cases where we know an item needs to have a certain type
      # which doesn't apply to custom types.
      def unfiltered_base_types
        # TODO: Remove the comment once we integrate the system defined types in the provider
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
        # if use_system_defined_types?
        #   type_class.all.map(&:base_type)
        # else
        #   type_class.base_types.keys
        # end

        type_class.base_types.keys
      end

      # This method exists here because we want to have full control in this class
      # about how types are treated in the application.
      def unfiltered_base_types_for_issue_type
        unfiltered_base_types.map(&:upcase)
      end

      def filtered_types
        # TODO: filter base types using the TypesFilter
        # See https://gitlab.com/gitlab-org/gitlab/-/work_items/585707
        type_class.all
      end

      def all
        type_class.all
      end

      def by_base_types(names)
        type_class.by_type(names)
      end

      def ids_by_base_types(types)
        # TODO: Remove the comment once we integrate the system defined types in the provider
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
        # if use_system_defined_types?
        #   by_base_types(types).map(&:id)
        # else
        #   Array(types).filter_map do |type|
        #     type_class::BASE_TYPES.dig(type.to_sym, :id)
        #   end
        # end

        Array(types).filter_map do |type|
          type_class::BASE_TYPES.dig(type.to_sym, :id)
        end
      end

      def type_exists?(type)
        type_class.base_types.key?(type.to_s)
      end

      def find_by_base_type(name)
        type_class.default_by_type(name)
      end

      def find_by_name(name)
        type_class.find_by(name: name.to_s)
      end

      def default_issue_type
        type_class.default_issue_type
      end

      def find_by_gid(gid)
        model_id = gid.try(:model_id)
        return unless model_id.present?

        find_by_id(model_id)
      end

      # Id is ambiguous in terms of system-defined and custom types.
      # So we'll deprecate this method long term.
      #
      # This has some API related usages where a work item type id is passed.
      # We should change these interfaces to use a GID instead so we can properly distinguish
      # between system-defined and custom types.
      #
      # For now it looks like we can use the GID in most cases.
      def find_by_id(id)
        type_class.find_by(id: id.to_i)
      end

      def by_ids(ids)
        integer_ids = Array.wrap(ids).map(&:to_i)
        type_class.where(id: integer_ids)
      end

      # This method should be removed as it's only used in the old WorkItems::Type model
      # and not in the new WorkItems::TypesFramework::SystemDefined::Type model.
      # The `with_widget_definition_preload` method is specific to the old model
      # and is not needed when using system-defined types.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/581931
      def by_ids_with_widget_definition_preload(ids)
        # TODO: Remove the comment once we integrate the system defined types in the provider
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
        #   if use_system_defined_types?
        #     by_ids(ids)
        #   else
        #     by_ids(ids).with_widget_definition_preload
        #   end

        by_ids(ids).with_widget_definition_preload
      end

      def base_types_by_ids(ids)
        type_class.where(id: ids).map(&:base_type).uniq
      end

      def all_ordered_by_name
        type_class.order_by_name_asc
      end

      def by_ids_ordered_by_name(ids)
        # TODO: Remove the comment once we integrate the system defined types in the provider
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
        # if use_system_defined_types?
        #   type_class.by_ids_ordered_by_name(ids)
        # else
        #   by_ids(ids).order_by_name_asc
        # end

        by_ids(ids).order_by_name_asc
      end

      def by_base_types_ordered_by_name(names)
        # TODO: Remove the comment once we integrate the system defined types in the provider
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
        #
        # if use_system_defined_types?
        #   type_class.by_base_type_ordered_by_name(names)
        # else
        #   by_base_types(names).order_by_name_asc
        # end

        by_base_types(names).order_by_name_asc
      end

      private

      def type_class
        # TODO: Introduce system defined types behind feature flag here.
        # See https://gitlab.com/gitlab-org/gitlab/-/work_items/581926
        WorkItems::Type
      end

      def use_system_defined_types?
        Feature.enabled?(:work_item_system_defined_type, :instance)
      end
    end
  end
end
