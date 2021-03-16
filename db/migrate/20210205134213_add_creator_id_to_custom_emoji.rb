# frozen_string_literal: true

class AddCreatorIdToCustomEmoji < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # Custom Emoji is at the moment behind a default-disabled feature flag. It
    # will be unlikely there are any records in this table, but to able to
    # ensure a not-null constraint delete any existing rows.
    # Roll-out issue: https://gitlab.com/gitlab-org/gitlab/-/issues/231317
    execute 'DELETE FROM custom_emoji'

    add_reference :custom_emoji, # rubocop:disable Migration/AddReference
                  :creator,
                  index: true,
                  null: false, # rubocop:disable Rails/NotNullColumn
                  foreign_key: false # FK is added in 20210219100137
  end

  def down
    remove_reference :custom_emoji, :creator
  end
end
