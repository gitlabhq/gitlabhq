# frozen_string_literal: true

# For large tables, PostgreSQL can take a long time to count rows due to MVCC.
# We can optimize this by using various strategies for approximate counting.
#
# For example, we can use the reltuples count as described in https://wiki.postgresql.org/wiki/Slow_Counting.
#
# However, since statistics are not always up to date, we also implement a table sampling strategy
# that performs an exact count but only on a sample of the table. See TablesampleCountStrategy.
module Gitlab
  module Database
    module Count
      CONNECTION_ERRORS =
        if defined?(PG)
          [
            ActionView::Template::Error,
            ActiveRecord::StatementInvalid,
            PG::Error
          ].freeze
        else
          [
            ActionView::Template::Error,
            ActiveRecord::StatementInvalid
          ].freeze
        end

      ORGANIZATION_SCOPE = :in_organization

      # Takes in an array of models and returns a Hash for the approximate
      # counts for them.
      #
      # Various count strategies can be specified that are executed in
      # sequence until all tables have an approximate count attached
      # or we run out of strategies.
      #
      # Note that not all strategies are available on all supported RDBMS.
      #
      # @param [Array]
      # @return [Hash] of Model -> count mapping
      def self.approximate_counts(models, strategies: [])
        if strategies.empty?
          # ExactCountStrategy is the only strategy working on read-only DBs, as others make
          # use of tuple stats which use the primary DB to estimate tables size in a transaction.
          strategies = if ::Gitlab::Database.read_write?
                         [TablesampleCountStrategy, ReltuplesCountStrategy, ExactCountStrategy]
                       else
                         [ExactCountStrategy]
                       end
        end

        strategies.each_with_object({}) do |strategy, counts_by_model|
          models_with_missing_counts = models - counts_by_model.keys

          break counts_by_model if models_with_missing_counts.empty?

          counts = strategy.new(models_with_missing_counts).count

          counts.each do |model, count|
            counts_by_model[model] = count
          end
        end
      end

      # Counts each model scoped to a single organization.
      #
      # A regular organization is counted exactly, but the default organization
      # holds effectively every row, so we fall back to .approximate_counts
      # there to avoid the whole-table scan an exact count would trigger.
      #
      # Scope overrides only apply to the exact path. Prefer scopes backed by a
      # single indexed `organization_id`; join-based scopes (Snippet, Member)
      # are far more expensive to count and are unbounded here.
      #
      # A model whose count times out is omitted so one slow table cannot fail
      # the whole batch.
      #
      # @param models [Array] models to count
      # @param organization [Organizations::Organization] the organization to scope by
      # @param scopes [Hash] optional Model => scope name overrides (e.g. { User => :member_of_organization })
      # @return [Hash] of Model -> count mapping
      def self.approximate_counts_for_organization(models, organization, scopes: {})
        models.each { |model| validate_organization_scope!(model, scopes) }

        return approximate_counts(models) if organization.default?

        models.index_with do |model|
          organization_count(model, organization, scopes)
        end.compact
      end

      def self.validate_organization_scope!(model, scopes)
        scope_name = scopes.fetch(model, ORGANIZATION_SCOPE)

        return if model.respond_to?(scope_name)

        raise ArgumentError, "#{model} does not respond to :#{scope_name} for organization scoping"
      end
      private_class_method :validate_organization_scope!

      def self.organization_count(model, organization, scopes)
        scope_name = scopes.fetch(model, ORGANIZATION_SCOPE)

        model.public_send(scope_name, organization).count # rubocop:disable GitlabSecurity/PublicSend -- scope existence checked in validate_organization_scope!
      rescue *CONNECTION_ERRORS
        nil
      end
      private_class_method :organization_count
    end
  end
end
