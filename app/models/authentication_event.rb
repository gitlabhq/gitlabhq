# frozen_string_literal: true

class AuthenticationEvent < ApplicationRecord
  belongs_to :user, optional: true

  validates :provider, :user_name, :result, presence: true

  enum result: {
    failed: 0,
    success: 1
  }
end
