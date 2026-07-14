# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_license, class: '::Gitlab::Ci::Reports::Sbom::License' do
    sequence(:name) { |n| "custom-license-#{n}" }

    trait :with_expression do
      name { nil }
      expression { "Apache-2.0 AND (MIT OR GPL-2.0-only)" }
    end
  end
end
