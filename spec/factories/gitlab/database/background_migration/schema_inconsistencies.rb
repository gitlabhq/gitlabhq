# frozen_string_literal: true

FactoryBot.define do
  factory :schema_inconsistency, class: '::Gitlab::Database::SchemaValidation::SchemaInconsistency' do
    issue factory: :issue

    object_name { 'name' }
    table_name { 'table' }
    valitador_name { 'validator' }
  end
end
