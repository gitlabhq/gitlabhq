# frozen_string_literal: true

FactoryBot.define do
  factory :project_data_transfer, class: 'Projects::DataTransfer' do
    project factory: :project
    namespace { project.root_namespace }
    date { Time.current.utc.beginning_of_month }
    repository_egress { 1 }
    artifacts_egress { 2 }
    packages_egress { 3 }
    registry_egress { 4 }
  end
end
