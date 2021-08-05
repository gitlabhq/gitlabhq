# frozen_string_literal: true

class AddLabelAppliedIssuableClosedToIssuableSla < ActiveRecord::Migration[6.1]
  def change
    add_column :issuable_slas, :label_applied, :boolean, default: false, null: false
    add_column :issuable_slas, :issuable_closed, :boolean, default: false, null: false
  end
end
