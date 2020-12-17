# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_index_bloat_estimate, class: 'Gitlab::Database::PostgresIndexBloatEstimate' do
    association :index, factory: :postgres_index

    identifier { index.identifier }
    bloat_size_bytes { 10.megabytes }
  end
end
