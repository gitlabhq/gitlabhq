# frozen_string_literal: true

FactoryBot.define do
  factory :users_star_project do
    project
    user
  end
end
