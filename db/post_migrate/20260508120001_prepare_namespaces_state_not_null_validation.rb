# frozen_string_literal: true

class PrepareNamespacesStateNotNullValidation < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  CONSTRAINT_NAME = 'check_9d490f2140'

  def up
    prepare_async_check_constraint_validation :namespaces, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :namespaces, name: CONSTRAINT_NAME
  end
end
