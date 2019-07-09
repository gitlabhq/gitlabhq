# frozen_string_literal: true

class AddMergeRequestRebaseJid < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_column :merge_requests, :rebase_jid, :string
  end
end
