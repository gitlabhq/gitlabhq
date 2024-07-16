# frozen_string_literal: true

class AddMlCandidateMetadataProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :ml_candidate_metadata,
      sharding_key: :project_id,
      parent_table: :ml_candidates,
      parent_sharding_key: :project_id,
      foreign_key: :candidate_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ml_candidate_metadata,
      sharding_key: :project_id,
      parent_table: :ml_candidates,
      parent_sharding_key: :project_id,
      foreign_key: :candidate_id
    )
  end
end
