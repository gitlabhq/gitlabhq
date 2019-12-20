# frozen_string_literal: true

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    extend ::Gitlab::Utils::Override

    def self.single
      @single ||= Class.new(self) do
        def resolve(**args)
          super.first
        end
      end
    end

    def self.last
      @last ||= Class.new(self) do
        def resolve(**args)
          super.last
        end
      end
    end

    def self.resolver_complexity(args, child_complexity:)
      complexity = 1
      complexity += 1 if args[:sort]
      complexity += 5 if args[:search]

      complexity
    end

    def self.complexity_multiplier(args)
      # When fetching many items, additional complexity is added to the field
      # depending on how many items is fetched. For each item we add 1% of the
      # original complexity - this means that loading 100 items (our default
      # maxp_age_size limit) doubles the original complexity.
      #
      # Complexity is not increased when searching by specific ID(s), because
      # complexity difference is minimal in this case.
      [args[:iid], args[:iids]].any? ? 0 : 0.01
    end

    override :object
    def object
      super.tap do |obj|
        # If the field this resolver is used in is wrapped in a presenter, go back to it's subject
        break obj.subject if obj.is_a?(Gitlab::View::Presenter::Base)
      end
    end
  end
end
