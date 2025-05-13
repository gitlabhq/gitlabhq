# frozen_string_literal: true

FactoryBot.define do
  factory :personal_snippet, class: 'Gitlab::Backup::Cli::Models::PersonalSnippet' do
    sequence(:id)
    repository_storage { 'snippets_storage' }
  end
end
