# frozen_string_literal: true

FactoryBot.define do
  factory :project_data_transfer, class: 'Projects::DataTransfer' do
    project factory: :project
    namespace { project.root_namespace }
    date { Time.current.utc.beginning_of_month }
  end
end
