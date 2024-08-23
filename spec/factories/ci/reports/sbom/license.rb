# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_license, class: '::Gitlab::Ci::Reports::Sbom::License' do
    sequence(:name) { |n| "custom-license-#{n}" }
  end
end
