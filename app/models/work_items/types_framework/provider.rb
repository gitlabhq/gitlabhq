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
        type_class.all.map(&:base_type)
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
        resolve_all
      end

      def by_base_types(names)
        Array(names).filter_map { |name| resolve_by_base_type(name.to_s) }
      end

      def ids_by_base_types(types)
        by_base_types(types).map(&:id)
      end

      def type_exists?(type)
        type_class.base_types.key?(type.to_s)
      end

      def find_by_base_type(name)
        resolve_by_base_type(name.to_s)
      end

      def find_by_name(name)
        name_str = name.to_s
        resolve_all.find { |type| type.name == name_str }
      end

      def default_issue_type
        find_by_base_type(:issue)
      end

      def find_by_gid(gid)
        model_id = gid.try(:model_id)
        return unless model_id.present?

        find_by_id(model_id)
      end

      def find_by_id(id)
        resolve_by_id(id.to_i)
      end

      def by_ids(ids)
        Array.wrap(ids).filter_map { |id| resolve_by_id(id.to_i) }
      end

      def base_types_by_ids(ids)
        by_ids(ids).map(&:base_type).uniq
      end

      def all_ordered_by_name
        resolve_all.sort_by { |type| type.name.downcase }
      end

      def by_ids_ordered_by_name(ids)
        by_ids(ids).sort_by { |type| type.name.downcase }
      end

      def by_base_types_ordered_by_name(names)
        by_base_types(names).sort_by { |type| type.name.downcase }
      end

      private

      # Override in EE to include custom types via the indexed cache.
      # In CE, resolves from system-defined types only.
      def resolve_by_id(id)
        type_class.find_by(id: id)
      end

      # Override in EE to return the converted custom type when one exists.
      # In CE, returns the system-defined type for the given base_type.
      def resolve_by_base_type(name)
        type_class.default_by_type(name)
      end

      # Override in EE to return all types (system-defined + custom) from the indexed cache.
      # In CE, returns system-defined types only.
      def resolve_all
        type_class.all
      end

      def type_class
        WorkItems::TypesFramework::SystemDefined::Type
      end
    end
  end
end

WorkItems::TypesFramework::Provider.prepend_mod
