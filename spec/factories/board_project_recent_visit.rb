# frozen_string_literal: true

FactoryBot.define do
  factory :board_project_recent_visit do
    user
    project
    board
  end
end
