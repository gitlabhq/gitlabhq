# frozen_string_literal: true

class ChangePmAdvisoriesUrlsConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = "chk_rails_e73af9de76"

  def up
    remove_check_constraint :pm_advisories, CONSTRAINT_NAME
    add_check_constraint :pm_advisories, "CARDINALITY(urls) <= 20", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :pm_advisories, CONSTRAINT_NAME
    add_check_constraint :pm_advisories, "CARDINALITY(urls) <= 10", CONSTRAINT_NAME
  end
end
