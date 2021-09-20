# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_flag, class: '::Gitlab::Ci::Reports::Security::Flag' do
    type { 'flagged-as-likely-false-positive' }
    origin { 'post analyzer X' }
    description { 'static string to sink' }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Flag.new(**attributes)
    end
  end
end
