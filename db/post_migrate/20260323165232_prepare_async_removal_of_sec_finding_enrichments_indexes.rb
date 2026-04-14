# frozen_string_literal: true

class PrepareAsyncRemovalOfSecFindingEnrichmentsIndexes < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  EPSS_SCORE_INDEX_NAME = 'index_sec_finding_enrichments_on_epss_score'
  KEV_INDEX_NAME = 'index_sec_finding_enrichments_on_is_known_exploit'

  def up
    prepare_async_index_removal :security_finding_enrichments, :epss_score, name: EPSS_SCORE_INDEX_NAME
    prepare_async_index_removal :security_finding_enrichments, :is_known_exploit, name: KEV_INDEX_NAME
  end

  def down
    unprepare_async_index :security_finding_enrichments, :epss_score, name: EPSS_SCORE_INDEX_NAME
    unprepare_async_index :security_finding_enrichments, :is_known_exploit, name: KEV_INDEX_NAME
  end
end
