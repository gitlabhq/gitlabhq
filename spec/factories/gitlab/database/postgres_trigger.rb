# frozen_string_literal: true

FactoryBot.define do
  factory :postgres_trigger, class: 'Gitlab::Database::PostgresTrigger' do
    identifier { "#{schema_name}.#{table_name}.#{trigger_name}" }
    trigger_name { 'foo_trigger' }
    table_name { 'foo' }
    schema_name { 'public' }
    function_name { 'foo_function' }
  end
end
