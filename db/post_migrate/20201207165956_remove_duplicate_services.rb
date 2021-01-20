# frozen_string_literal: true

class RemoveDuplicateServices < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # noop, replaced by 20210112143418_remove_duplicate_services.rb
  end

  def down
  end
end
