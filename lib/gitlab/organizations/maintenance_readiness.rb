# frozen_string_literal: true

module Gitlab
  module Organizations
    # Cutover-readiness check for entering the steady `maintenance` state.
    # TODO: remaining checks need to be implemented https://gitlab.com/gitlab-org/gitlab/-/work_items/602822
    class MaintenanceReadiness
      def initialize(organization)
        @organization = organization
      end

      def ready?
        no_active_batched_background_migrations?
      end

      private

      attr_reader :organization

      def no_active_batched_background_migrations?
        active = false

        ::Gitlab::Database::EachDatabase.each_connection(include_shared: false) do
          active ||= ::Gitlab::Database::BackgroundMigration::BatchedMigration.with_status(:active).exists?

          break if active
        end

        !active
      end
    end
  end
end
