# frozen_string_literal: true

FactoryBot.define do
  factory :repository_language do
    project
    programming_language
    share 98.5
  end
end
