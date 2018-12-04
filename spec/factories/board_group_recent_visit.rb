# frozen_string_literal: true

FactoryBot.define do
  factory :board_group_recent_visit do
    user
    group
    board
  end
end
