# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_partitioned_table, class: 'Gitlab::Database::PostgresPartitionedTable' do
    identifier { "#{schema}.#{name}" }
    sequence(:oid) { |n| n }
    schema { 'public' }
    name { '_test_partitioned_table' }
    strategy { 'range' }
    key_columns { ['timestamp'] }
  end
end
