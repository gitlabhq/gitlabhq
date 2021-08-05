# frozen_string_literal: true

module Namespaces
  module Traversal
    module RecursiveScopes
      extend ActiveSupport::Concern

      class_methods do
        def as_ids
          select('id')
        end

        def self_and_descendants
          Gitlab::ObjectHierarchy.new(all).base_and_descendants
        end
        alias_method :recursive_self_and_descendants, :self_and_descendants

        def self_and_descendant_ids
          self_and_descendants.as_ids
        end
        alias_method :recursive_self_and_descendant_ids, :self_and_descendant_ids
      end
    end
  end
end
