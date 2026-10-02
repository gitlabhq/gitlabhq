# frozen_string_literal: true

class AddTriagePartialIndexesToSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = :security_inventory_filters
  INCLUDE_COLUMNS = %i[triage_capabilities_on triage_capabilities_auto]

  # bit => mask taken from Security::TriageCoverage::CapabilityBitmask::BITS
  INDEXES = {
    'idx_sec_inv_filters_traversal_proj_sbom_ingested_on' => 1,  # sbom_ingested
    'idx_sec_inv_filters_traversal_proj_sast_fp_on' => 2,        # sast_false_positive
    'idx_sec_inv_filters_traversal_proj_secret_fp_on' => 8       # secret_detection_false_positive
  }.freeze

  def up
    INDEXES.each do |index_name, mask|
      add_concurrent_index(
        TABLE_NAME,
        %i[traversal_ids project_id],
        name: index_name,
        include: INCLUDE_COLUMNS,
        where: "NOT archived AND (triage_capabilities_on & #{mask}) > 0"
      )
    end
  end

  def down
    INDEXES.each_key do |index_name|
      remove_concurrent_index_by_name(TABLE_NAME, index_name)
    end
  end
end
