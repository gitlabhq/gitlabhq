# frozen_string_literal: true

# This migration is only relevant for the down migration case.
# It ensures that package protection rules with nil minimum_access_level_for_push are removed
# before the NOT NULL constraint is added in the previous down migration,
# i.e. 20250130161000_remove_not_null_constraint_from_mininum_access_level_for_push.rb .
# See the related discussion thread https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179739#note_2334019898
class RemovePackageProtectionRulesOnDownMigration < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class PackagesProtectionRule < MigrationRecord
    self.table_name = "packages_protection_rules"
  end

  def up
    # no-op
  end

  def down
    PackagesProtectionRule.where(minimum_access_level_for_push: nil).find_in_batches(batch_size: 100) do |ids|
      PackagesProtectionRule.where(id: ids).delete_all
    end
  end
end
