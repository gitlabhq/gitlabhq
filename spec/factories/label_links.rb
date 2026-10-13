# frozen_string_literal: true

FactoryBot.define do
  factory :label_link do
    label { @overrides[:own_label] || association(:label) }
    target factory: :issue
  end
end
