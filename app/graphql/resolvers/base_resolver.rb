# frozen_string_literal: true

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    argument_class ::Types::BaseArgument

    def self.requires_argument!
      @requires_argument = true
    end

    def self.requires_argument?
      !!@requires_argument
    end

    def self.calls_gitaly!
      @calls_gitaly = true
    end

    def self.calls_gitaly?
      !!@calls_gitaly
    end

    # This is a flag to allow us to use `complexity_multiplier` to compute complexity for connection
    # fields(see BaseField#connection_complexity_multiplier) in resolvers that do external connection pagination,
    # thus disabling the default `connection` option.
    def self.calculate_ext_conn_complexity
      false
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
      @single.instance_exec(&block) if @single.present?
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
            value = super

            if value.is_a?(Array)
              [value[0], select_result(value[1])]
            else
              value
            end
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
      @last ||= Class.new(single) do
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
      # max_page_size limit) doubles the original complexity.
      #
      # Complexity is not increased when searching by specific ID(s), because
      # complexity difference is minimal in this case.
      [args[:iid], args[:iids]].any? ? 0 : 0.01
    end

    def self.before_connection_authorization(&block)
      @before_connection_authorization_block = block
    end

    # rubocop: disable Style/TrivialAccessors
    def self.before_connection_authorization_block
      @before_connection_authorization_block
    end
    # rubocop: enable Style/TrivialAccessors

    def offset_pagination(relation)
      ::Gitlab::Graphql::Pagination::OffsetPaginatedRelation.new(relation)
    end

    override :object
    def object
      super.tap do |obj|
        # If the field this resolver is used in is wrapped in a presenter, unwrap its subject
        break obj.__subject__ if obj.is_a?(Gitlab::View::Presenter::Base)
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

    def self.authorization
      @authorization ||= ::Gitlab::Graphql::Authorize::ObjectAuthorization.new(try(:required_permissions))
    end

    def self.authorized?(object, context)
      authorization.ok?(object, context[:current_user], scope_validator: context[:scope_validator])
    end
  end
end
