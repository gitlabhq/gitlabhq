# frozen_string_literal: true

FactoryBot.define do
  factory :project_snippet, class: 'Gitlab::Backup::Cli::Models::ProjectSnippet' do
    sequence(:id)
    repository_storage { 'snippets_storage' }
    path_with_namespace { 'group/myproject' }
  end
end
