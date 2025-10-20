# frozen_string_literal: true

class PrepareAsyncCheckNotNullConstraintOnRedirectRoutes < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = 'check_e82ff70482'

  def up
    prepare_async_check_constraint_validation :redirect_routes, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :redirect_routes, name: CONSTRAINT_NAME
  end
end
