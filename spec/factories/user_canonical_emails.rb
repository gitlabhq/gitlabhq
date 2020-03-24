# frozen_string_literal: true

FactoryBot.define do
  factory :user_canonical_email do
    user
    canonical_email { user.email }
  end
end
