# frozen_string_literal: true

class ListUserPreference < ApplicationRecord
  belongs_to :user
  belongs_to :list

  validates :user, presence: true
  validates :list, presence: true
  validates :user_id, uniqueness: { scope: :list_id, message: "should have only one list preference per user" }
end
