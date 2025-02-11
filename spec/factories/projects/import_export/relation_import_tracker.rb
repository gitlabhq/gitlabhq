# frozen_string_literal: true

FactoryBot.define do
  factory :relation_import_tracker, class: 'Projects::ImportExport::RelationImportTracker' do
    association :project, factory: :project

    relation { :issues }
    status { 0 }

    trait :started do
      status { 1 }
    end

    trait :finished do
      status { 2 }
    end

    trait :stale do
      created_at { (Projects::ImportExport::RelationImportTracker::STALE_TIMEOUT + 1).ago }
    end
  end
end
