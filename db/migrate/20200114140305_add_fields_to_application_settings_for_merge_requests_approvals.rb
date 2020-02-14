# frozen_string_literal: true

class AddFieldsToApplicationSettingsForMergeRequestsApprovals < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column(:application_settings,
                :disable_overriding_approvers_per_merge_request,
                :boolean,
                default: false,
                null: false)
    add_column(:application_settings,
                :prevent_merge_requests_author_approval,
                :boolean,
                default: false,
                null: false)
    add_column(:application_settings,
                :prevent_merge_requests_committers_approval,
                :boolean,
                default: false,
                null: false)
  end

  def down
    remove_column(:application_settings, :disable_overriding_approvers_per_merge_request)
    remove_column(:application_settings, :prevent_merge_requests_author_approval)
    remove_column(:application_settings, :prevent_merge_requests_committers_approval)
  end
end
