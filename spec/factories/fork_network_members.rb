# frozen_string_literal: true

FactoryBot.define do
  factory :fork_network_member do
    association :project
    association :fork_network

    forked_from_project { fork_network.root_project }
  end
end
