# frozen_string_literal: true

FactoryBot.define do
  factory :snippet_repository_storage_move, class: 'Snippets::RepositoryStorageMove' do
    container { association(:snippet) }

    source_storage_name { 'default' }

    trait :scheduled do
      state { Snippets::RepositoryStorageMove.state_machines[:state].states[:scheduled].value }
    end

    trait :started do
      state { Snippets::RepositoryStorageMove.state_machines[:state].states[:started].value }
    end

    trait :replicated do
      state { Snippets::RepositoryStorageMove.state_machines[:state].states[:replicated].value }
    end

    trait :finished do
      state { Snippets::RepositoryStorageMove.state_machines[:state].states[:finished].value }
    end

    trait :failed do
      state { Snippets::RepositoryStorageMove.state_machines[:state].states[:failed].value }
    end
  end
end
