# frozen_string_literal: true

FactoryBot.define do
  factory :container_registry_protection_rule, class: 'ContainerRegistry::Protection::Rule' do
    project
    repository_path_pattern { project.full_path }
    minimum_access_level_for_delete { :maintainer }
    minimum_access_level_for_push { :maintainer }
  end
end
