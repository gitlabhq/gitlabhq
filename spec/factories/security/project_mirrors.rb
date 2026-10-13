# frozen_string_literal: true

FactoryBot.define do
  factory :security_project_mirror, class: 'Security::ProjectMirror' do
    project
    namespace_id { project.namespace_id }
    organization_id { project.organization_id }
  end
end
