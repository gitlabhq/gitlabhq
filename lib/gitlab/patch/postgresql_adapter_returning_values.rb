# frozen_string_literal: true

# The `sql.active_record` notification payload carries the SQL text but not
# the PG::Result, so subscribers never see the values produced by
# `INSERT ... RETURNING`. Rails yields the notification payload to the block
# that executes the query (it populates `row_count` through the same seam),
# which lets us expose those values to subscribers such as
# Gitlab::Database::QueryAnalyzers::Capture.
module Gitlab
  module Patch
    module PostgresqlAdapterReturningValues
      RETURNING_PATTERN = /\bRETURNING\b/i

      # This guard is load-bearing, not an optimization. Capture.enabled?
      # calls Feature.enabled?, which on a cold cache issues its own SQL
      # through this same patched method. So no flag is checked here: the
      # Capture analyzer's thread-local context, set once per request/job,
      # gates enrichment instead and is nil in migrations and specs.
      def log(sql, *args, **kwargs)
        return super unless block_given? &&
          Gitlab::Database::QueryAnalyzers::Capture.context &&
          sql&.match?(RETURNING_PATTERN)

        super do |notification_payload|
          yield(notification_payload).tap do |result|
            if result.is_a?(PG::Result) && result.ntuples > 0
              notification_payload[:returned_values] = {
                fields: result.fields,
                values: result.values
              }
            end
          end
        end
      end
    end
  end
end
