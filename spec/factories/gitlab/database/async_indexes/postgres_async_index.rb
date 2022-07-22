# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_async_index, class: 'Gitlab::Database::AsyncIndexes::PostgresAsyncIndex' do
    sequence(:name) { |n| "users_id_#{n}" }
    definition { "CREATE INDEX #{name} ON #{table_name} (id)" }
    table_name { "users" }

    trait :with_drop do
      definition { "DROP INDEX #{name}" }
    end
  end
end
