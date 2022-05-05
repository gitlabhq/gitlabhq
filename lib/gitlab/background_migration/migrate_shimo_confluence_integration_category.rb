# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The class to migrate category of integrations to third_party_wiki for confluence and shimo
    class MigrateShimoConfluenceIntegrationCategory
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, end_id)
        define_batchable_model('integrations', connection: ApplicationRecord.connection)
          .where(id: start_id..end_id, type_new: %w[Integrations::Confluence Integrations::Shimo])
          .update_all(category: 'third_party_wiki')

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
