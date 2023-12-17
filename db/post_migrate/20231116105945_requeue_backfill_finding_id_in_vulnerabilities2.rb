# frozen_string_literal: true

class RequeueBackfillFindingIdInVulnerabilities2 < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  # marking as no-op as per our database guidelines
  def up; end

  def down; end
end
