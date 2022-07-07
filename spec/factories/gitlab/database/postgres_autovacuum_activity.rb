# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_autovacuum_activity, class: 'Gitlab::Database::PostgresAutovacuumActivity' do
    table_identifier { "#{schema}.#{table}" }
    schema { 'public' }
    table { 'projects' }
    vacuum_start { Time.zone.now - 3.minutes }
  end
end
