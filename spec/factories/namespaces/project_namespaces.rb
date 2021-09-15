# frozen_string_literal: true

FactoryBot.define do
  factory :project_namespace, class: 'Namespaces::ProjectNamespace' do
    project
    name { project.name }
    path { project.path }
    type { Namespaces::ProjectNamespace.sti_name }
    owner { nil }
  end
end
