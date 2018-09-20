# frozen_string_literal: true

module Gitlab
  module Database
    module Subquery
      class << self
        def self_join(relation)
          t = relation.arel_table
          t2 = relation.arel.as('t2')

          relation.unscoped.joins(t.join(t2).on(t[:id].eq(t2[:id])).join_sources.first)
        end
      end
    end
  end
end
