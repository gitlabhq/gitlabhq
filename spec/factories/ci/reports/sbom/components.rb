# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_component, class: '::Gitlab::Ci::Reports::Sbom::Component' do
    type { "library" }
    sequence(:name) { |n| "component-#{n}" }
    sequence(:version) { |n| "v0.0.#{n}" }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Sbom::Component.new(
        type: type,
        name: name,
        version: version
      )
    end
  end
end
