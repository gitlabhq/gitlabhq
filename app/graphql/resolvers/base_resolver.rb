# frozen_string_literal: true

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize
    include ::Gitlab::Graphql::GlobalIDCompatibility

    argument_class ::Types::BaseArgument

    def self.requires_argument!
      @requires_argument = true
    end

    def self.field_options
      super.merge(requires_argument: @requires_argument)
    end

    def self.singular_type
      return unless type

      unwrapped = type.unwrap

      %i[node_type relay_node_type of_type itself].reduce(nil) do |t, m|
        t || unwrapped.try(m)
      end
    end

    def self.when_single(&block)
      as_single << block

      # Have we been called after defining the single version of this resolver?
      if @single.present?
        @single.instance_exec(&block)
      end
    end

    def self.as_single
      @as_single ||= []
    end

    def self.single_definition_blocks
      ancestors.flat_map { |klass| klass.try(:as_single) || [] }
    end

    def self.single
      @single ||= begin
        parent = self
        klass = Class.new(self) do
          type parent.singular_type, null: true

          def ready?(**args)
            ready, early_return = super
            [ready, select_result(early_return)]
          end

          def resolve(**args)
            select_result(super)
          end

          def single?
            true
          end

          def select_result(results)
            results&.first
          end

          define_singleton_method :to_s do
            "#{parent}.single"
          end
        end

        single_definition_blocks.each do |definition|
          klass.instance_exec(&definition)
        end

        klass
      end
    end

    def self.last
      parent = self
      @last ||= Class.new(self.single) do
        type parent.singular_type, null: true

        def select_result(results)
          results&.last
        end

        define_singleton_method :to_s do
          "#{parent}.last"
        end
      end
    end

    def self.complexity
      0
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

    def offset_pagination(relation)
      ::Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection.new(relation)
    end

    override :object
    def object
      super.tap do |obj|
        # If the field this resolver is used in is wrapped in a presenter, unwrap its subject
        break obj.subject if obj.is_a?(Gitlab::View::Presenter::Base)
      end
    end

    # TODO: remove! This should never be necessary
    # Remove as part of https://gitlab.com/gitlab-org/gitlab/-/issues/13984,
    # since once we use that authorization approach, the object is guaranteed to
    # be synchronized before any field.
    def synchronized_object
      strong_memoize(:synchronized_object) do
        ::Gitlab::Graphql::Lazy.force(object)
      end
    end

    def single?
      false
    end

    def current_user
      context[:current_user]
    end

    # Overridden in sub-classes (see .single, .last)
    def select_result(results)
      results
    end
  end
end
