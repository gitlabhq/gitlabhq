# frozen_string_literal: true

module Gitlab
  module Graphql
    # This module allows your class to easily defer and force values.
    # Its methods are just sugar for calls to the Gitlab::Graphql::Lazy class.
    #
    # example:
    #
    #  class MyAwesomeClass
    #    include ::Gitlab::Graphql::Laziness
    #
    #    # takes a list of id and list of factors, and computes
    #    # sum of [SomeObject[i]#value * factor[i]]
    #    def resolve(ids:, factors:)
    #      ids.zip(factors)
    #        .map { |id, factor| promise_an_int(id, factor) }
    #        .map(&method(:force))
    #        .sum
    #    end
    #
    #    # returns a promise for an Integer
    #    def (id, factor)
    #      thunk = SomeObject.lazy_find(id)
    #      defer { force(thunk).value * factor }
    #    end
    #  end
    #
    # In the example above, we use defer to delay forcing the batch-loaded
    # item until we need it, and then we use `force` to consume the lazy values
    #
    # If `SomeObject.lazy_find(id)` batches correctly, calling
    # `resolve` will only perform one batched load for all objects, rather than
    # loading them individually before combining the results.
    #
    module Laziness
      def defer(&block)
        ::Gitlab::Graphql::Lazy.new(&block)
      end

      def force(lazy)
        ::Gitlab::Graphql::Lazy.force(lazy)
      end
    end
  end
end
