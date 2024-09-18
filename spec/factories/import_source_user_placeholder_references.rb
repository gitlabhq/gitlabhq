# frozen_string_literal: true

FactoryBot.define do
  factory :import_source_user_placeholder_reference, class: 'Import::SourceUserPlaceholderReference' do
    source_user factory: :import_source_user
    namespace { source_user.namespace }
    model { 'Note' }
    user_reference_column { 'author_id' }
    alias_version { 1 }
    numeric_key { 1 }
  end
end
