# frozen_string_literal: true

FactoryBot.define do
  factory :project_design_management, class: 'Gitlab::Backup::Cli::Models::ProjectDesignManagement' do
    sequence(:id)
    repository_storage { 'design_storage' }
    path_with_namespace { 'group/project' }
    name_with_namespace { 'My Group / My Project' }
  end
end
