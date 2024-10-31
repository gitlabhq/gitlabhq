# frozen_string_literal: true

module Namespaces
  module Traversal
    module Recursive
      extend ActiveSupport::Concern
      include RecursiveScopes

      def root_ancestor
        if persisted? && !parent_id.nil?
          strong_memoize(:root_ancestor) do
            recursive_ancestors.reorder(nil).find_top_level
          end
        elsif parent.nil?
          self
        else
          parent.root_ancestor
        end
      end
      alias_method :recursive_root_ancestor, :root_ancestor

      def all_project_ids
        namespace = user_namespace? ? self : recursive_self_and_descendant_ids
        Project.where(namespace: namespace).select(:id)
      end
      alias_method :recursive_all_project_ids, :all_project_ids

      # Returns all ancestors, self, and descendants of the current namespace.
      def self_and_hierarchy
        object_hierarchy(self.class.where(id: id))
          .all_objects
      end
      alias_method :recursive_self_and_hierarchy, :self_and_hierarchy

      # Returns all the ancestors of the current namespaces.
      def ancestors(hierarchy_order: nil)
        return self.class.none unless parent_id

        object_hierarchy(self.class.where(id: parent_id))
          .base_and_ancestors(hierarchy_order: hierarchy_order)
      end
      alias_method :recursive_ancestors, :ancestors

      def ancestor_ids(hierarchy_order: nil)
        recursive_ancestors(hierarchy_order: hierarchy_order).pluck(:id)
      end
      alias_method :recursive_ancestor_ids, :ancestor_ids

      # returns all ancestors upto but excluding the given namespace
      # when no namespace is given, all ancestors upto the top are returned
      def ancestors_upto(top = nil, hierarchy_order: nil)
        object_hierarchy(self.class.where(id: id))
          .ancestors(upto: top, hierarchy_order: hierarchy_order)
      end
      alias_method :recursive_ancestors_upto, :ancestors_upto

      def self_and_ancestors(hierarchy_order: nil)
        return self.class.where(id: id) unless parent_id

        object_hierarchy(self.class.where(id: id))
          .base_and_ancestors(hierarchy_order: hierarchy_order)
      end
      alias_method :recursive_self_and_ancestors, :self_and_ancestors

      def self_and_ancestor_ids(hierarchy_order: nil)
        recursive_self_and_ancestors(hierarchy_order: hierarchy_order).pluck(:id)
      end
      alias_method :recursive_self_and_ancestor_ids, :self_and_ancestor_ids

      # Returns all the descendants of the current namespace.
      def descendants
        object_hierarchy(self.class.where(parent_id: id)).base_and_descendants
      end
      alias_method :recursive_descendants, :descendants

      def self_and_descendants(skope: self.class)
        object_hierarchy(skope.where(id: id)).base_and_descendants
      end
      alias_method :recursive_self_and_descendants, :self_and_descendants

      def self_and_descendant_ids(skope: self.class)
        object_hierarchy(skope.where(id: id)).base_and_descendant_ids
      end
      alias_method :recursive_self_and_descendant_ids, :self_and_descendant_ids

      def object_hierarchy(ancestors_base)
        Gitlab::ObjectHierarchy.new(ancestors_base)
      end
    end
  end
end
