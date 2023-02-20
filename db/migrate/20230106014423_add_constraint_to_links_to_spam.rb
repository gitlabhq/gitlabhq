# frozen_string_literal: true

class AddConstraintToLinksToSpam < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = "abuse_reports_links_to_spam_length_check"

  def up
    add_check_constraint :abuse_reports, "CARDINALITY(links_to_spam) <= 20", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :abuse_reports, CONSTRAINT_NAME
  end
end
