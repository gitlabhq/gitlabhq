# frozen_string_literal: true

namespace :ci do
  desc 'CI | Catalog | Collect bundles for existing versions of published GitLab-maintained catalog resources'
  task backfill_catalog_bundles: :environment do
    require_relative './backfill_catalog_bundles_task'

    Tasks::Ci::BackfillCatalogBundlesTask.new.execute
  end
end
