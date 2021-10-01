# frozen_string_literal: true

module ActiveRecordRelationAllowCrossJoins
  def allow_cross_joins_across_databases(url:)
    # this method is implemented in:
    # spec/support/database/prevent_cross_joins.rb
    self
  end
end

ActiveRecord::Relation.prepend(ActiveRecordRelationAllowCrossJoins)
