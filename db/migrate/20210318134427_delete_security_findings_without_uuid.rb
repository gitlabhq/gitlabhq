# frozen_string_literal: true

class DeleteSecurityFindingsWithoutUuid < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  class SecurityFinding < ActiveRecord::Base
    include EachBatch

    self.table_name = 'security_findings'

    scope :without_uuid, -> { where(uuid: nil) }
  end

  def up
    SecurityFinding.without_uuid.each_batch(of: 10_000) do |relation|
      relation.delete_all
    end
  end

  def down
    # no-op
  end
end
