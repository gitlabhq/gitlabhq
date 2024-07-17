# frozen_string_literal: true

module RuboCop
  module Cop
    module BackgroundMigration
      # Checks for rescuing errors inside batched background migration job classes.
      #
      # @example
      #
      #   # bad
      #   def perform
      #     do_something
      #   rescue StandardError => error
      #     logger.error(error.message)
      #   end
      #
      #   # bad
      #   def perform
      #     do_something
      #   rescue JSON::ParserError, ActiveRecord::StatementTimeout => error
      #     logger.error(error.message)
      #   end
      #
      #   # good
      #   def perform
      #     do_something
      #   rescue StandardError => error
      #     logger.error(error.message)
      #
      #     raise
      #   end
      #
      #   # good
      #   def perform
      #     do_something
      #   rescue JSON::ParserError, ActiveRecord::StatementTimeout => error
      #     logger.error(error.message)
      #
      #     raise MyCustomException
      #   end
      class AvoidSilentRescueExceptions < RuboCop::Cop::Base
        MSG = 'Avoid rescuing exceptions inside job classes. See ' \
              'https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#best-practices'

        def_node_matcher :batched_migration_job_class?, <<~PATTERN
          (class
            const
            (const {nil? cbase const} :BatchedMigrationJob)
            ...
          )
        PATTERN

        # Matches rescued exceptions that were not re-raised
        #
        # @example
        #         rescue => error
        #         rescue Exception => error
        #         rescue JSON::ParserError => e
        #         rescue ActiveRecord::StatementTimeout => error
        #         rescue ActiveRecord::StatementTimeout, ActiveRecord::QueryCanceled => error
        def_node_matcher :rescue_timeout_error, <<~PATTERN
          (resbody $_ _ (... !(send nil? :raise ...)))
        PATTERN

        def on_class(node)
          @batched_migration_job_class ||= batched_migration_job_class?(node)
        end

        def on_resbody(node)
          return unless batched_migration_job_class

          rescue_timeout_error(node) do |error|
            range = error ? node.loc.keyword.join(error.loc.expression) : node.loc.keyword
            add_offense(range)
          end
        end

        private

        attr_reader :batched_migration_job_class
      end
    end
  end
end
