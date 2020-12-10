# frozen_string_literal: true

FactoryBot.define do
  factory :reindex_action, class: 'Gitlab::Database::Reindexing::ReindexAction' do
    association :index, factory: :postgres_index

    action_start { Time.now - 10.minutes }
    action_end { Time.now - 5.minutes }
    ondisk_size_bytes_start { 2.megabytes }
    ondisk_size_bytes_end { 1.megabytes }
    state { Gitlab::Database::Reindexing::ReindexAction.states[:finished] }
    index_identifier { index.identifier }
  end
end
