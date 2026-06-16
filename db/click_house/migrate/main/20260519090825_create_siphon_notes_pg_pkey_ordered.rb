# frozen_string_literal: true

class CreateSiphonNotesPgPkeyOrdered < ClickHouse::Migration
  def up
    # noop, redefined in:
    # db/click_house/migrate/main/20260521072213_re_create_siphon_notes_pg_pkey_ordered.rb
  end

  def down
    # noop
  end
end
