# frozen_string_literal: true

FactoryBot.define do
  factory :relation_import_tracker, class: 'Projects::ImportExport::RelationImportTracker' do
    association :project, factory: :project

    relation { :issues }
    status { 0 }
  end
end
