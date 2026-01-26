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

      # This list of types will exclude custom types because they're based on top of the `issue` base type.
      # We use the base types in cases where we know an item needs to have a certain type
      # which doesn't apply to custom types.
      def unfiltered_base_types
        # TODO: Introduce system defined types behind feature flag here.
        # See https://gitlab.com/gitlab-org/gitlab/-/work_items/581926
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

        type_class.find_by_id(model_id)
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
        type_class.find_by_id(id)
      end

      def by_ids(ids)
        type_class.where(id: ids)
      end

      def all_ordered_by_name
        type_class.order_by_name_asc
      end

      def by_ids_ordered_by_name(ids)
        by_ids(ids).order_by_name_asc
      end

      def by_base_types_ordered_by_name(names)
        by_base_types(names).order_by_name_asc
      end

      private

      def type_class
        # TODO: Introduce system defined types behind feature flag here.
        # See https://gitlab.com/gitlab-org/gitlab/-/work_items/581926
        WorkItems::Type
      end
    end
  end
end
