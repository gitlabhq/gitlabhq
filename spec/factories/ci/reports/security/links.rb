# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_link, class: '::Gitlab::Ci::Reports::Security::Link' do
    name { 'CVE-2020-0202' }
    url { 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-0202' }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Link.new(**attributes)
    end
  end
end
