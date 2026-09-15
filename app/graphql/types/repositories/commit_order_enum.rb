# frozen_string_literal: true

module Types
  module Repositories
    class CommitOrderEnum < BaseEnum
      graphql_name 'CommitOrder'
      description 'Ordering strategy for a list of commits. Defaults to reverse chronological when omitted.'

      value 'TOPO', value: 'topo', description: 'Topological order: children are shown before their parents.'
      value 'DATE', value: 'date', description: 'Date order: commits are shown strictly by commit date.'
    end
  end
end
