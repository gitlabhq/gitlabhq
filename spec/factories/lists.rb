# frozen_string_literal: true

FactoryBot.define do
  factory :list do
    board
    label
    list_type :label
    sequence(:position)
  end

  factory :backlog_list, parent: :list do
    list_type :backlog
    label nil
    position nil
  end

  factory :closed_list, parent: :list do
    list_type :closed
    label nil
    position nil
  end
end
