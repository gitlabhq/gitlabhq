# frozen_string_literal: true

class PopulateRemainingMissingDismissalInformationForVulnerabilities < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('PopulateMissingVulnerabilityDismissalInformation')

    ::Gitlab::BackgroundMigration::PopulateMissingVulnerabilityDismissalInformation::Vulnerability.broken.each_batch(of: 100) do |batch, index|
      vulnerability_ids = batch.pluck(:id)

      ::Gitlab::BackgroundMigration::PopulateMissingVulnerabilityDismissalInformation.new.perform(*vulnerability_ids)
    end
  end

  def down
    # no-op
  end
end
