# frozen_string_literal: true

class SetResolvedStateOnVulnerabilities < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    execute <<~SQL
    -- selecting IDs for all non-orphan Findings that either have no feedback or it's a non-dismissal feedback
    WITH resolved_vulnerability_ids AS (
      SELECT DISTINCT vulnerability_id AS id
      FROM vulnerability_occurrences
      LEFT JOIN vulnerability_feedback ON vulnerability_feedback.project_fingerprint = ENCODE(vulnerability_occurrences.project_fingerprint::bytea, 'HEX')
      WHERE vulnerability_id IS NOT NULL
      AND (vulnerability_feedback.id IS NULL OR vulnerability_feedback.feedback_type <> 0)
    )
    UPDATE vulnerabilities
    SET state = 3, resolved_by_id = closed_by_id, resolved_at = NOW()
    FROM resolved_vulnerability_ids
    WHERE vulnerabilities.id IN (resolved_vulnerability_ids.id)
    AND state = 2 -- only 'closed' Vulnerabilities become 'resolved'
    SQL
  end

  def down
    execute <<~SQL
    UPDATE vulnerabilities
    SET state = 2, resolved_by_id = NULL, resolved_at = NULL -- state = 'closed'
    WHERE state = 3 -- 'resolved'
    SQL
  end
end
