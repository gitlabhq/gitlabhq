# frozen_string_literal: true

class ValidateTimelogsNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    validate_foreign_key :timelogs, :namespace_id, name: 'fk_d774bdf1ae'
  end

  def down
    # no-op
  end
end
