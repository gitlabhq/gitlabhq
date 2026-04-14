# frozen_string_literal: true

module WorkItems
  module TypesFramework
    # This is the single source of truth to fetch work item types.
    #
    # In the future namespaces can use system-defined and custom work item types.
    # This class aims to abstract that fetching logic away so application code doesn't need to care
    # about the composition of types of a given namespace.
    #
    # For now, we use this interface to fetch types from the database to make the switchover easier.
    # We already use the final methods from the POC, but will change the implementation using caching etc.
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214894
    class Provider
      include Gitlab::Utils::StrongMemoize

      ALL_BASE_TYPES = %w[issue incident test_case requirement task objective key_result epic ticket].freeze

      class << self
        def unfiltered_base_types
          ALL_BASE_TYPES
        end

        # Returns base types that can be used as issue types.
        # This method supports legacy systems that work with issue types
        # (e.g., API endpoints, issue type enums, build parameters).
        def unfiltered_base_types_for_issues
          unfiltered_base_types.excluding('epic', 'key_result', 'objective')
        end
      end

      def initialize(namespace = nil)
        # Always try to pass the current namespace or subtypes(Group, Project::Namespace) and not the root ancestor.
        #
        # We will use it to fetch custom types and apply the TypesFilter.
        #
        # For custom types we need to either
        # 1. fetch types by organization_id of the namespace for Self-Managed
        # 2. fetch types by the root group for Saas
        #
        # See https://gitlab.com/groups/gitlab-org/-/work_items/20291
        #
        # NOTE: If a `Project` instance is passed, we automatically use its `project_namespace`.
        # Projects are not Namespace objects and will cause unexpected behaviour otherwise.
        @namespace = namespace.is_a?(::Project) ? namespace.project_namespace : namespace
      end

      attr_reader :namespace

      def fetch_work_item_type(work_item_type)
        work_item_type_id = work_item_type.respond_to?(:id) ? work_item_type.id : work_item_type
        find_by_id(work_item_type_id)
      end

      def all
        resolve_all
      end

      # Temporary method to maintain compatibility for deprecated
      # name and onlyAvailable args that will be removed in 19.0
      def allowed_types
        return [] if resource_parent.blank?
        return [] unless project_namespace?

        filtered_types
      end

      # Override in EE
      # TODO: Integrate filtering into .all
      # https://gitlab.com/gitlab-org/gitlab/-/work_items/585707
      def filtered_types
        all
      end

      def available_system_defined_types_count
        filtered_types.count { |type| type.is_a?(::WorkItems::TypesFramework::SystemDefined::Type) }
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

      def resource_parent
        return if namespace.nil?
        return namespace if namespace.is_a?(::Organizations::Organization)

        # Return nil for user namespaces - these don't support advanced work item types
        return if namespace.owner_entity_name == :user

        # Return nil for projects under user namespaces - they inherit the user namespace restrictions
        # return if root_ancestor.owner_entity_name == :user

        ::Gitlab::SafeRequestStore.fetch("work_items_types_provider_resource_parent_#{namespace.id}") do
          namespace.owner_entity
        end
      end
      strong_memoize_attr :resource_parent

      def root_ancestor
        return if namespace.nil?
        return namespace if namespace.is_a?(::Organizations::Organization)

        cache_key = namespace.try(:traversal_ids)&.first || namespace.id
        ::Gitlab::SafeRequestStore.fetch("work_items_types_provider_root_ancestor_#{cache_key}") do
          namespace.try(:root_ancestor)
        end
      end
      strong_memoize_attr :root_ancestor

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

      def project_namespace?
        resource_parent.is_a?(::Project)
      end
    end
  end
end

WorkItems::TypesFramework::Provider.prepend_mod
