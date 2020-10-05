# frozen_string_literal: true

FactoryBot.define do
  factory :project_tracing_setting do
    project
    external_url { 'https://example.com' }
  end
end
