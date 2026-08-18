# frozen_string_literal: true

FactoryBot.define do
  factory :ci_catalog_bundled_resource, class: 'Ci::Catalog::BundledResource' do
    server_fqdn { 'gitlab.com' }
    sequence(:full_path) { |n| "gitlab-org/components/component-#{n}" }
    name { 'Bundled component' }
  end
end
