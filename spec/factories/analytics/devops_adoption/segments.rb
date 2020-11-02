# frozen_string_literal: true

FactoryBot.define do
  factory :devops_adoption_segment, class: 'Analytics::DevopsAdoption::Segment' do
    sequence(:name) { |n| "Segment #{n}" }
  end
end
