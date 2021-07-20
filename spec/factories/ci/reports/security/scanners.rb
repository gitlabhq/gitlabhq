# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_scanner, class: '::Gitlab::Ci::Reports::Security::Scanner' do
    external_id { 'find_sec_bugs' }
    name { 'Find Security Bugs' }
    vendor { 'Security Scanner Vendor' }
    version { '1.0.0' }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Scanner.new(**attributes)
    end
  end

  factory :ci_reports_security_scan, class: '::Gitlab::Ci::Reports::Security::Scan' do
    status { 'success' }
    type { 'sast' }
    start_time { 'placeholder' }
    end_time { 'placeholder' }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Scan.new(attributes)
    end
  end
end
