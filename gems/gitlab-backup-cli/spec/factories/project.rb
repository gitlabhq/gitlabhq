# frozen_string_literal: true

FactoryBot.define do
  factory :project, class: 'Gitlab::Backup::Cli::Models::Project' do
    sequence(:id)
    repository_storage { 'storage' }
    path_with_namespace { 'group/project' }
    name_with_namespace { 'My Group / My Project' }
  end
end
