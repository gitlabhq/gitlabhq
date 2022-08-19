# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_index, class: 'Gitlab::Database::PostgresIndex' do
    identifier { "public.some_index_#{indexrelid}" }
    sequence(:indexrelid) { |n| n }
    schema { 'public' }
    name { "some_index_#{indexrelid}" }
    tablename { 'foo' }
    unique { false }
    valid_index { true }
    partitioned { false }
    exclusion { false }
    expression { false }
    partial { false }
    definition { "CREATE INDEX #{identifier} ON #{tablename} (bar)" }
    ondisk_size_bytes { 100.megabytes }
  end
end
