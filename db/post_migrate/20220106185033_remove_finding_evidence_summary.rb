# frozen_string_literal: true

class RemoveFindingEvidenceSummary < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    remove_column :vulnerability_finding_evidences, :summary, :text
  end

  def down
    add_column :vulnerability_finding_evidences, :summary, :text

    add_text_limit :vulnerability_finding_evidences, :summary, 8_000_000
  end
end
