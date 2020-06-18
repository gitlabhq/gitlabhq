# frozen_string_literal: true

FactoryBot.define do
  factory :evidence, class: 'Releases::Evidence' do
    release
    summary_sha { "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d" }
    summary { { "release": { "tag": "v4.0", "name": "New release", "project_name": "Project name" } } }
  end
end
