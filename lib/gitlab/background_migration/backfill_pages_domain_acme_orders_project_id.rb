# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPagesDomainAcmeOrdersProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_pages_domain_acme_orders_project_id
      feature_category :pages
    end
  end
end
