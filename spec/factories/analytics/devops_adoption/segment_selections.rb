# frozen_string_literal: true

FactoryBot.define do
  factory :devops_adoption_segment_selection, class: 'Analytics::DevopsAdoption::SegmentSelection' do
    association :segment, factory: :devops_adoption_segment
    project

    trait :project do
      group { nil }
      project
    end

    trait :group do
      project { nil }
      group
    end
  end
end
