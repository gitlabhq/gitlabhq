# frozen_string_literal: true

FactoryBot.define do
  factory :project_repository_storage_move, class: 'ProjectRepositoryStorageMove' do
    project

    source_storage_name { 'default' }

    trait :scheduled do
      state { ProjectRepositoryStorageMove.state_machines[:state].states[:scheduled].value }
    end

    trait :started do
      state { ProjectRepositoryStorageMove.state_machines[:state].states[:started].value }
    end

    trait :replicated do
      state { ProjectRepositoryStorageMove.state_machines[:state].states[:replicated].value }
    end

    trait :finished do
      state { ProjectRepositoryStorageMove.state_machines[:state].states[:finished].value }
    end

    trait :failed do
      state { ProjectRepositoryStorageMove.state_machines[:state].states[:failed].value }
    end
  end
end
