# frozen_string_literal: true

class Namespace::Detail < ApplicationRecord
  include IgnorableColumns

  ignore_column :free_user_cap_over_limt_notified_at, remove_with: '15.7', remove_after: '2022-11-22'

  belongs_to :namespace, inverse_of: :namespace_details
  validates :namespace, presence: true
  validates :description, length: { maximum: 255 }

  self.primary_key = :namespace_id
end

Namespace::Detail.prepend_mod
