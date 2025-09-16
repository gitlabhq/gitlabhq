# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_table_size, class: 'Gitlab::Database::PostgresTableSize' do
    sequence(:identifier) { |n| "table_#{n}" }
    schema_name { 'public' }
    table_name { 'foo' }
    total_size { '3 GB' }
    table_size { '1 GB' }
    toast_size { '1 GB' }
    index_size { '1 GB' }
    size_in_bytes { 3.gigabytes }
  end
end
