# frozen_string_literal: true

FactoryBot.define do
  factory :project_repository_storage_move, class: 'ProjectRepositoryStorageMove' do
    project

    source_storage_name { 'default' }
    destination_storage_name { 'default' }

    trait :scheduled do
      state { ProjectRepositoryStorageMove.state_machines[:state].states[:scheduled].value }
    end
  end
end
