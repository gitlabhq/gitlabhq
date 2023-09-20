# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_metadata, class: '::Gitlab::Ci::Reports::Sbom::Metadata' do
    transient do
      vendor { generate(:name) }
      author_name { generate(:name) }
    end

    tools do
      [
        {
          vendor: vendor,
          name: "Gemnasium",
          version: "2.34.0"
        }
      ]
    end
    authors do
      [
        {
          name: author_name,
          email: "support@gitlab.com"
        }
      ]
    end
    properties do
      [
        {
          name: "gitlab:dependency_scanning:input_file:path",
          value: "package-lock.json"
        },
        {
          name: "gitlab:dependency_scanning:package_manager:name",
          value: "npm"
        }
      ]
    end

    skip_create

    initialize_with { new(tools: tools, authors: authors, properties: properties) }
  end
end
