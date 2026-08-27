# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      # Decides if we can safely detach a partition.
      #
      # Detaching a partition that a foreign key references makes Postgres prove that no referencing
      # row survives. It proves that by querying every referencing table, and that query runs inside
      # the DETACH statement, holding its locks for as long as the read takes. So we decline while
      # any foreign key references the parent, and record which one.
      class DetachEligibility
        include ::Gitlab::Utils::StrongMemoize

        Blocker = Struct.new(:reason, :level, :details, keyword_init: true)

        attr_reader :blocker

        def initialize(partition, connection:)
          @partition = partition
          @connection = connection
          @blocker = nil
        end

        def detachable?
          with_connection do
            foreign_key = referencing_foreign_key
            next true unless foreign_key

            blocked_by(:referencing_foreign_key, :warn,
              referencing_table: foreign_key.constrained_table_identifier,
              foreign_key_name: foreign_key.name)

            false
          end
        end
        strong_memoize_attr :detachable?

        private

        attr_reader :partition, :connection

        def referencing_foreign_key
          PostgresForeignKey.by_referenced_table_identifier(parent_identifier).first
        end

        def parent_identifier
          "#{connection.current_schema}.#{partition.table}"
        end

        # Records why the detach cannot go ahead.
        def blocked_by(reason, level, **details)
          @blocker = Blocker.new(reason: reason, level: level, details: details)
        end

        def with_connection(&block)
          Gitlab::Database::SharedModel.using_connection(connection, &block)
        end
      end
    end
  end
end
