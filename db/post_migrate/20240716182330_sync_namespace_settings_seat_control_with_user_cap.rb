# frozen_string_literal: true

class SyncNamespaceSettingsSeatControlWithUserCap < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  milestone '17.3'

  def up
    define_batchable_model('namespace_settings').where.not(new_user_signups_cap: nil).each_batch do |relation|
      relation.update_all(seat_control: 1)
    end
  end

  def down
    # no-op
  end
end
