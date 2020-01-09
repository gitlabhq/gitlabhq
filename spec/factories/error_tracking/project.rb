# frozen_string_literal: true

FactoryBot.define do
  factory :error_tracking_project, class: 'Gitlab::ErrorTracking::Project' do
    id { '1' }
    name { 'Sentry Example' }
    slug { 'sentry-example' }
    status { 'active' }
    organization_name { 'Sentry' }
    organization_id { '1' }
    organization_slug { 'sentry' }

    skip_create
  end
end
