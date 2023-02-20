# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_async_foreign_key_validation,
    class: 'Gitlab::Database::AsyncForeignKeys::PostgresAsyncForeignKeyValidation' do
    sequence(:name) { |n| "fk_users_id_#{n}" }
    table_name { "users" }
  end
end
