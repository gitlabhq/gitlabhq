# frozen_string_literal: true

FactoryBot.define do
  factory :project_relation_export, class: 'Projects::ImportExport::RelationExport' do
    project_export_job factory: :project_export_job

    relation { 'labels' }
    status { Projects::ImportExport::RelationExport::STATUS[:queued] }
    sequence(:jid) { |n| "project_relation_export_#{n}" }

    trait :queued do
      status { Projects::ImportExport::RelationExport::STATUS[:queued] }
    end

    trait :started do
      status { Projects::ImportExport::RelationExport::STATUS[:started] }
    end

    trait :finished do
      status { Projects::ImportExport::RelationExport::STATUS[:finished] }
    end

    trait :failed do
      status { Projects::ImportExport::RelationExport::STATUS[:failed] }
    end
  end
end
