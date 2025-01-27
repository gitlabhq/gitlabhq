# frozen_string_literal: true

class PrepareProjectNamespaceIdNotNullValidation < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  CONSTRAINT_NAME = 'check_fa75869cb1'

  def up
    prepare_async_check_constraint_validation :projects, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :projects, name: CONSTRAINT_NAME
  end
end
