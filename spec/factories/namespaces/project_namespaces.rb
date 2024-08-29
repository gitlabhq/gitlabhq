# frozen_string_literal: true

FactoryBot.define do
  factory :project_namespace, class: 'Namespaces::ProjectNamespace' do
    association :project, factory: :project, strategy: :build
    parent { project.namespace }
    visibility_level { project.visibility_level }
    name { project.name }
    path { project.path }
    type { Namespaces::ProjectNamespace.sti_name }
    owner { nil }
    organization { parent.organization }
  end
end
