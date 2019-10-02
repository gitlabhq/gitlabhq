# frozen_string_literal: true

FactoryBot.define do
  factory :project_daily_statistic do
    project
    fetch_count { 1 }
  end
end
