# frozen_string_literal: true

FactoryBot.define do
  factory :reindexing_queued_action, class: 'Gitlab::Database::Reindexing::QueuedAction' do
    association :index, factory: :postgres_index

    state { Gitlab::Database::Reindexing::QueuedAction.states[:queued] }
    index_identifier { index.identifier }
  end
end
