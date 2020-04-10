# frozen_string_literal: true

module WhereComposite
  extend ActiveSupport::Concern

  class TooManyIds < ArgumentError
    LIMIT = 100

    def initialize(no_of_ids)
      super(<<~MSG)
      At most #{LIMIT} identifier sets at a time please! Got #{no_of_ids}.
      Have you considered splitting your request into batches?
      MSG
    end

    def self.guard(collection)
      n = collection.size
      return collection if n <= LIMIT

      raise self, n
    end
  end

  class_methods do
    # Apply a set of constraints that function as composite IDs.
    #
    # This is the plural form of the standard ActiveRecord idiom:
    # `where(foo: x, bar: y)`, except it allows multiple pairs of `x` and
    # `y` to be specified, with the semantics that translate to:
    #
    # ```sql
    # WHERE
    #     (foo = x_0 AND bar = y_0)
    #  OR (foo = x_1 AND bar = y_1)
    #  OR ...
    # ```
    #
    # or the equivalent:
    #
    # ```sql
    # WHERE
    #   (foo, bar) IN ((x_0, y_0), (x_1, y_1), ...)
    # ```
    #
    # @param permitted_keys [Array<Symbol>] The keys each hash must have. There
    #                                       must be at least one key (but really,
    #                                       it ought to be at least two)
    # @param hashes [Array<#to_h>|#to_h] The constraints. Each parameter must have a
    #                                    value for the keys named in `permitted_keys`
    #
    # e.g.:
    # ```
    #   where_composite(%i[foo bar], [{foo: 1, bar: 2}, {foo: 1, bar: 3}])
    # ```
    #
    def where_composite(permitted_keys, hashes)
      raise ArgumentError, 'no permitted_keys' unless permitted_keys.present?

      # accept any hash-like thing, such as Structs
      hashes = TooManyIds.guard(Array.wrap(hashes)).map(&:to_h)

      return none if hashes.empty?

      case permitted_keys.size
      when 1
        key = permitted_keys.first
        where(key => hashes.map { |hash| hash.fetch(key) })
      else
        clauses = hashes.map do |hash|
          permitted_keys.map do |key|
            arel_table[key].eq(hash.fetch(key))
          end.reduce(:and)
        end

        where(clauses.reduce(:or))
      end
    rescue KeyError
      raise ArgumentError, "all arguments must contain #{permitted_keys}"
    end
  end
end
