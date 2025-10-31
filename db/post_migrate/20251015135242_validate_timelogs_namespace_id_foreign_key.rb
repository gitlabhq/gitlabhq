# frozen_string_literal: true

class ValidateTimelogsNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_d774bdf1ae'

  milestone '18.6'

  def up
    validate_foreign_key :timelogs, :namespace_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
