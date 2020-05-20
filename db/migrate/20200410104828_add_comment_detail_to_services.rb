# frozen_string_literal: true

class AddCommentDetailToServices < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :services, :comment_detail, :smallint
  end

  def down
    remove_column :services, :comment_detail
  end
end
