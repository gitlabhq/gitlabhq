# frozen_string_literal: true

class ReplaceVulnDetectionTransitionsIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  NEW_INDEX_NAME = 'idx_vuln_detection_transitions_on_occurrence_id_id'
  OLD_INDEX_NAME = 'idx_vuln_detection_transitions_on_occurrence_id_detected_id'

  def up
    add_concurrent_index(
      :vulnerability_detection_transitions,
      [:vulnerability_occurrence_id, :id],
      name: NEW_INDEX_NAME
    )

    remove_concurrent_index_by_name(
      :vulnerability_detection_transitions,
      OLD_INDEX_NAME
    )
  end

  def down
    add_concurrent_index(
      :vulnerability_detection_transitions,
      [:vulnerability_occurrence_id, :detected, :id],
      name: OLD_INDEX_NAME
    )

    remove_concurrent_index_by_name(
      :vulnerability_detection_transitions,
      NEW_INDEX_NAME
    )
  end
end
