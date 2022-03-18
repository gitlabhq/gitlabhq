# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      # Given a class, it finds or creates a new object at group level.
      #
      # Example:
      #   `Group::ObjectBuilder.build(Label, label_attributes)`
      #    finds or initializes a label with the given attributes.
      class ObjectBuilder < Base::ObjectBuilder
        def initialize(klass, attributes)
          super

          @group = @attributes['group']
        end

        private

        attr_reader :group

        def where_clauses
          [
            where_clause_base,
            where_clause_for_title,
            where_clause_for_description,
            where_clause_for_created_at
          ].compact
        end

        # Returns Arel clause `"{table_name}"."group_id" = {group.id}`
        def where_clause_base
          table[:group_id].in(group_and_ancestor_ids)
        end

        def group_and_ancestor_ids
          group.ancestors.map(&:id) << group.id
        end
      end
    end
  end
end
