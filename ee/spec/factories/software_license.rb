# frozen_string_literal: true

FactoryBot.define do
  factory :software_license, class: SoftwareLicense do
    sequence(:name) { |n| "SOFTWARE-LICENSE-2.7/example_#{n}" }
  end
end
