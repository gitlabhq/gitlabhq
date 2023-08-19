# frozen_string_literal: true

class Namespace::Detail < ApplicationRecord
  include IgnorableColumns

  ignore_column :dashboard_notification_at, remove_with: '16.5', remove_after: '2023-08-22'
  ignore_column :dashboard_enforcement_at, remove_with: '16.5', remove_after: '2023-08-22'
  ignore_column :next_over_limit_check_at, remove_with: '16.5', remove_after: '2023-08-22'
  ignore_column :free_user_cap_over_limit_notified_at, remove_with: '16.5', remove_after: '2023-08-22'

  belongs_to :namespace, inverse_of: :namespace_details
  validates :namespace, presence: true
  validates :description, length: { maximum: 255 }

  self.primary_key = :namespace_id
end

Namespace::Detail.prepend_mod
