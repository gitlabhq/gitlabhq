# frozen_string_literal: true

module Gitlab
  module Database
    module Subquery
      class << self
        def self_join(relation)
          t = relation.arel_table
          t2 = if !Gitlab.rails5?
                 relation.arel.as('t2')
               else
                 # Work around a bug in Rails 5, where LIMIT causes trouble
                 # See https://gitlab.com/gitlab-org/gitlab-ce/issues/51729
                 r = relation.limit(nil).arel
                 r.take(relation.limit_value) if relation.limit_value
                 r.as('t2')
               end

          relation.unscoped.joins(t.join(t2).on(t[:id].eq(t2[:id])).join_sources.first)
        end
      end
    end
  end
end
