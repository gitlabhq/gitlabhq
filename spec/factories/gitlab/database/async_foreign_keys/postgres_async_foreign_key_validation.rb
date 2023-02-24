# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_async_constraint_validation,
    class: 'Gitlab::Database::AsyncConstraints::PostgresAsyncConstraintValidation' do
    sequence(:name) { |n| "fk_users_id_#{n}" }
    table_name { "users" }
  end
end
