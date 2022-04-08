# frozen_string_literal: true

class UserCustomAttribute < ApplicationRecord
  belongs_to :user

  validates :user_id, :key, :value, presence: true
  validates :key, uniqueness: { scope: [:user_id] }

  def self.upsert_custom_attributes(custom_attributes)
    created_at = DateTime.now
    updated_at = DateTime.now

    custom_attributes.map! do |custom_attribute|
      custom_attribute.merge({ created_at: created_at, updated_at: updated_at })
    end
    upsert_all(custom_attributes, unique_by: [:user_id, :key])
  end
end
