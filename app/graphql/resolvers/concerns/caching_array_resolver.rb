# frozen_string_literal: true

# Concern that will eliminate N+1 queries for size-constrained
# collections of items.
#
# **note**: The resolver will never load more items than
# `@field.max_page_size` if defined, falling back to
# `context.schema.default_max_page_size`.
#
# provided that:
#
# - the query can be uniquely determined by the object and the arguments
# - the model class includes FromUnion
# - the model class defines a scalar primary key
#
# This comes at the cost of returning arrays, not relations, so we don't get
# any keyset pagination goodness. Consequently, this is only suitable for small-ish
# result sets, as the full result set will be loaded into memory.
#
# To enforce this, the resolver limits the size of result sets to
# `@field.max_page_size || context.schema.default_max_page_size`.
#
# **important**: If the cardinality of your collection is likely to be greater than 100,
# then you will want to pass `max_page_size:` as part of the field definition
# or (ideally) set `max_page_size` in the resolver.
#
# How to implement:
# --------------------
#
# Each including class operates on two generic parameters, A and R:
#  - A is any Object that can be used as a Hash key. Instances of A
#    are returned by `query_input` and then passed to `query_for`.
#  - R is any subclass of ApplicationRecord that includes FromUnion.
#    R must have a single scalar primary_key
#
# Classes must implement:
# - #model_class -> Class[R]. (Must respond to  :primary_key, and :from_union)
# - #query_input(**kwargs) -> A (Must be hashable)
# - #query_for(A) -> ActiveRecord::Relation[R]
#
# Note the relationship between query_input and query_for, one of which
# consumes the input of the other
# (i.e. `resolve(**args).sync == query_for(query_input(**args)).to_a`).
#
# Classes may implement:
# - max_union_size Integer (the maximum number of queries to run in any one union)
# - preload -> Preloads|NilClass (a set of preloads to apply to each query)
# - #item_found(A, R) (return value is ignored)
# - allowed?(R) -> Boolean (if this method returns false, the value is not resolved)
module CachingArrayResolver
  MAX_UNION_SIZE = 50

  def resolve(**args)
    key = query_input(**args)

    BatchLoader::GraphQL.for(key).batch(**batch) do |keys, loader|
      if keys.size == 1
        # We can avoid the union entirely.
        k = keys.first
        limit(query_for(k)).each { |item| found(loader, k, item) }
      else
        queries = keys.map { |key| query_for(key) }

        queries.in_groups_of(max_union_size, false).each do |group|
          by_id = model_class
            .select(all_fields, :union_member_idx)
            .from_union(tag(group), remove_duplicates: false)
            .preload(preload) # rubocop: disable CodeReuse/ActiveRecord
            .group_by { |r| r[primary_key] }

          by_id.values.each do |item_group|
            item = item_group.first
            item_group.map(&:union_member_idx).each do |i|
              found(loader, keys[i], item)
            end
          end
        end
      end
    end
  end

  # Override to apply filters on a per-item basis
  def allowed?(item)
    true
  end

  # Override to specify preloads for each query
  def preload
    nil
  end

  # Override this to intercept the items once they are found
  def item_found(query_input, item); end

  def max_union_size
    MAX_UNION_SIZE
  end

  private

  def primary_key
    @primary_key ||= (model_class.primary_key || raise("No primary key for #{model_class}"))
  end

  def batch
    { key: self.class, default_value: [] }
  end

  def found(loader, key, value)
    return unless allowed?(value)

    loader.call(key) do |vs|
      item_found(key, value)
      vs << value
    end
  end

  # Tag each row returned from each query with a the index of which query in
  # the union it comes from. This lets us map the results back to the cache key.
  def tag(queries)
    queries.each_with_index.map do |q, i|
      limit(q.select(all_fields, member_idx(i)))
    end
  end

  def limit(query)
    query.limit(query_limit)
  end

  def all_fields
    model_class.arel_table[Arel.star]
  end

  # rubocop: disable Graphql/Descriptions -- false positive
  def query_limit
    field&.max_page_size.presence || context.schema.default_max_page_size
  end
  # rubocop: enable Graphql/Descriptions

  def member_idx(idx)
    ::Arel::Nodes::SqlLiteral.new(idx.to_s).as('union_member_idx')
  end
end
