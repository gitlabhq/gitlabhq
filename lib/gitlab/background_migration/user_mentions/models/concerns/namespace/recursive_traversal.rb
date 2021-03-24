# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        module Concerns
          module Namespace
            # isolate recursive traversal code for namespace hierarchy
            module RecursiveTraversal
              extend ActiveSupport::Concern

              def root_ancestor
                return self if persisted? && parent_id.nil?

                strong_memoize(:root_ancestor) do
                  Gitlab::ObjectHierarchy
                    .new(self.class.where(id: id))
                    .base_and_ancestors
                    .reorder(nil)
                    .find_by(parent_id: nil)
                end
              end

              # Returns all ancestors, self, and descendants of the current namespace.
              def self_and_hierarchy
                Gitlab::ObjectHierarchy
                  .new(self.class.where(id: id))
                  .all_objects
              end

              # Returns all the ancestors of the current namespaces.
              def ancestors
                return self.class.none unless parent_id

                Gitlab::ObjectHierarchy
                  .new(self.class.where(id: parent_id))
                  .base_and_ancestors
              end

              # returns all ancestors upto but excluding the given namespace
              # when no namespace is given, all ancestors upto the top are returned
              def ancestors_upto(top = nil, hierarchy_order: nil)
                Gitlab::ObjectHierarchy.new(self.class.where(id: id))
                  .ancestors(upto: top, hierarchy_order: hierarchy_order)
              end

              def self_and_ancestors(hierarchy_order: nil)
                return self.class.where(id: id) unless parent_id

                Gitlab::ObjectHierarchy
                  .new(self.class.where(id: id))
                  .base_and_ancestors(hierarchy_order: hierarchy_order)
              end

              # Returns all the descendants of the current namespace.
              def descendants
                Gitlab::ObjectHierarchy
                  .new(self.class.where(parent_id: id))
                  .base_and_descendants
              end

              def self_and_descendants
                Gitlab::ObjectHierarchy
                  .new(self.class.where(id: id))
                  .base_and_descendants
              end
            end
          end
        end
      end
    end
  end
end
