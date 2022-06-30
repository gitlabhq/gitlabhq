# frozen_string_literal: true

FactoryBot.define do
  factory :project_relation_export, class: 'Projects::ImportExport::RelationExport' do
    project_export_job factory: :project_export_job

    relation { 'labels' }
    status { 0 }
    sequence(:jid) { |n| "project_relation_export_#{n}" }
  end
end
