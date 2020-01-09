# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_project, class: 'Clusters::Project' do
    cluster
    project
  end
end
