# frozen_string_literal: true

module Namespaces
  module Traversal
    module RecursiveScopes
      extend ActiveSupport::Concern

      class_methods do
        def as_ids
          select('id')
        end

        def roots
          Gitlab::ObjectHierarchy
            .new(all)
            .base_and_ancestors
            .where(namespaces: { parent_id: nil })
        end

        def self_and_ancestors(include_self: true, upto: nil, hierarchy_order: nil)
          records = Gitlab::ObjectHierarchy.new(all).base_and_ancestors(upto: upto, hierarchy_order: hierarchy_order)

          if include_self
            records
          else
            records.where.not(id: all.as_ids)
          end
        end
        alias_method :recursive_self_and_ancestors, :self_and_ancestors

        def self_and_ancestor_ids(include_self: true)
          self_and_ancestors(include_self: include_self).as_ids
        end
        alias_method :recursive_self_and_ancestor_ids, :self_and_ancestor_ids

        def descendant_ids
          recursive_descendants.as_ids
        end
        alias_method :recursive_descendant_ids, :descendant_ids

        def self_and_descendants(include_self: true)
          base = if include_self
                   unscoped.where(id: all.as_ids)
                 else
                   unscoped.where(parent_id: all.as_ids)
                 end

          Gitlab::ObjectHierarchy.new(base).base_and_descendants
        end
        alias_method :recursive_self_and_descendants, :self_and_descendants

        def self_and_descendant_ids(include_self: true)
          self_and_descendants(include_self: include_self).as_ids
        end
        alias_method :recursive_self_and_descendant_ids, :self_and_descendant_ids

        def self_and_hierarchy
          Gitlab::ObjectHierarchy.new(all).all_objects
        end
        alias_method :recursive_self_and_hierarchy, :self_and_hierarchy
      end
    end
  end
end
