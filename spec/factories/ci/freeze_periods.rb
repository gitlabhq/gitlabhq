# frozen_string_literal: true

FactoryBot.define do
  factory :ci_freeze_period, class: 'Ci::FreezePeriod' do
    project
    freeze_start { '0 23 * * 5' }
    freeze_end { '0 7 * * 1' }
    cron_timezone { 'UTC' }
  end
end
