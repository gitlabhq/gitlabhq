# frozen_string_literal: true

FactoryBot.define do
  factory :application_setting do
    default_projects_limit { 42 }
    import_sources { [] }
  end
end
