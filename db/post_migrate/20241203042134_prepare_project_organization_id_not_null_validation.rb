# frozen_string_literal: true

class PrepareProjectOrganizationIdNotNullValidation < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  CONSTRAINT_NAME = 'check_1a6f946a8a'

  def up
    prepare_async_check_constraint_validation :projects, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :projects, name: CONSTRAINT_NAME
  end
end
