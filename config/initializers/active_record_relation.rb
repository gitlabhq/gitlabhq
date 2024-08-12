# frozen_string_literal: true

module ActiveRecord
  class Relation
    def null_relation?
      return super if ::Gitlab.next_rails?

      is_a?(ActiveRecord::NullRelation)
    end
  end
end
