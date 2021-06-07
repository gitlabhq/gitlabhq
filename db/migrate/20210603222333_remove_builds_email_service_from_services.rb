# frozen_string_literal: true

class RemoveBuildsEmailServiceFromServices < ActiveRecord::Migration[6.1]
  def up
    execute("DELETE from services WHERE type = 'BuildsEmailService'")
  end

  def down
    # no-op
  end
end
