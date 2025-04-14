# frozen_string_literal: true

FactoryBot.define do
  factory :fork_network do
    association :root_project, factory: :project

    before(:create) do |network|
      network.organization_id = network.root_project.organization_id
    end
  end
end
