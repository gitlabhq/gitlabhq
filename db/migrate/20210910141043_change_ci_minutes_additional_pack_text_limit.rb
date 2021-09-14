# frozen_string_literal: true

class ChangeCiMinutesAdditionalPackTextLimit < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    remove_text_limit :ci_minutes_additional_packs, :purchase_xid
    add_text_limit :ci_minutes_additional_packs, :purchase_xid, 50
  end

  def down
    remove_text_limit :ci_minutes_additional_packs, :purchase_xid
    add_text_limit :ci_minutes_additional_packs, :purchase_xid, 32, validate: false
  end
end
