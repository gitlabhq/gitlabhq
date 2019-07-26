# frozen_string_literal: true

FactoryBot.define do
  factory :label_link do
    label
    target factory: :issue
  end
end
