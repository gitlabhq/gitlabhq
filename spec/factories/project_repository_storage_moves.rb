# frozen_string_literal: true

FactoryBot.define do
  factory :project_repository_storage_move, class: 'Projects::RepositoryStorageMove' do
    container { association(:project) }

    source_storage_name { 'default' }

    trait :scheduled do
      state { Projects::RepositoryStorageMove.state_machines[:state].states[:scheduled].value }
    end

    trait :started do
      state { Projects::RepositoryStorageMove.state_machines[:state].states[:started].value }
    end

    trait :replicated do
      state { Projects::RepositoryStorageMove.state_machines[:state].states[:replicated].value }
    end

    trait :finished do
      state { Projects::RepositoryStorageMove.state_machines[:state].states[:finished].value }
    end

    trait :failed do
      state { Projects::RepositoryStorageMove.state_machines[:state].states[:failed].value }
    end
  end
end
