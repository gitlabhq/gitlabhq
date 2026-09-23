# frozen_string_literal: true

module Gitlab
  module Organizations
    # Cutover-readiness check for entering the steady `maintenance` state.
    # TODO: remaining checks need to be implemented https://gitlab.com/gitlab-org/gitlab/-/work_items/602822
    class MaintenanceReadiness
      def initialize(organization)
        @organization = organization
      end

      def blocking_reason
        return 'active batched background migrations' unless no_active_batched_background_migrations?
        return 'pending migrations' unless no_pending_migrations?
        return 'active CI jobs' unless no_active_ci_jobs?

        nil
      end

      private

      attr_reader :organization

      def no_active_batched_background_migrations?
        active = false

        ::Gitlab::Database::EachDatabase.each_connection(include_shared: false) do
          active = ::Gitlab::Database::BackgroundMigration::BatchedMigration.with_status(:active).exists?

          break if active
        end

        !active
      end

      def no_pending_migrations?
        pending = false

        ::Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |connection|
          pending = connection.pool.migration_context.needs_migration?

          break if pending
        end

        !pending
      end

      def no_active_ci_jobs?
        active = false

        ::Project.in_organization(organization).each_batch do |projects|
          active = ::Ci::Build.for_project_ids(projects.pluck_primary_key).alive.exists?

          break if active
        end

        !active
      end
    end
  end
end
