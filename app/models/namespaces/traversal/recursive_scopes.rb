# frozen_string_literal: true

module Namespaces
  module Traversal
    module RecursiveScopes
      extend ActiveSupport::Concern

      class_methods do
        def as_ids
          select('id')
        end

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
      end
    end
  end
end
