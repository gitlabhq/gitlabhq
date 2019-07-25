# frozen_string_literal: true

FactoryBot.define do
  factory :fork_network do
    association :root_project, factory: :project
  end
end
