# frozen_string_literal: true

class BackfillDraftStatusOnMergeRequests < ActiveRecord::Migration[6.0]
  # include Gitlab::Database::MigrationHelpers

  # Marking these as no-op as the original contents caused timeouts on
  #   staging. Removing the code here per
  #   #https://docs.gitlab.com/ee/development/deleting_migrations.html#how-to-disable-a-data-migration
  # =>
  def up
    # no-op
  end

  def down
    # no-op
  end
end
