# frozen_string_literal: true

FactoryBot.define do
  factory :project_wiki, class: 'Gitlab::Backup::Cli::Models::ProjectWiki' do
    sequence(:id)
    repository_storage { 'wiki_storage' }
    path_with_namespace { 'group/project' }
    name_with_namespace { 'My Group / My Project' }
  end
end
