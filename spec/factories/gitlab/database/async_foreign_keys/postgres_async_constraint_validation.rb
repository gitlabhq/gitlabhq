# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_async_constraint_validation,
    class: 'Gitlab::Database::AsyncConstraints::PostgresAsyncConstraintValidation' do
    sequence(:name) { |n| "fk_users_id_#{n}" }
    table_name { "users" }

    trait :foreign_key do
      constraint_type { :foreign_key }
    end

    trait :check_constraint do
      constraint_type { :check_constraint }
    end
  end
end
