# frozen_string_literal: true

module PaginatorExtension
  KEYSET_ORDER_PLACEHOLDER = Object.new

  # This method loads the records for the requested page and returns a keyset paginator object.
  def keyset_paginate(cursor: nil, per_page: 20, keyset_order_options: {})
    Gitlab::Pagination::Keyset::Paginator.new(scope: self.dup, cursor: cursor, per_page: per_page, keyset_order_options: keyset_order_options)
  end

  # This modifies `reverse_sql_order` so that it is aware of Gitlab::Pagination::Keyset::Order which
  # can reverse order clauses with NULLS LAST because we provide it a `reversed_order_expression`.
  # This allows us to use `#last` on these relations.
  #
  # Overrides https://github.com/rails/rails/blob/v6.1.6.1/activerecord/lib/active_record/relation/query_methods.rb#L1331-L1358
  def reverse_sql_order(order_query)
    return super if order_query.empty?

    keyset_order_values = []

    order_query_without_keyset = order_query.flat_map do |o|
      next o unless o.is_a?(Gitlab::Pagination::Keyset::Order)

      keyset_order_values << o
      KEYSET_ORDER_PLACEHOLDER
    end

    super(order_query_without_keyset).map do |o|
      next o unless o == KEYSET_ORDER_PLACEHOLDER

      keyset_order_values.shift.reversed_order
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.include(PaginatorExtension)
end
