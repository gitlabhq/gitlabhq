# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_finding_key, class: '::Gitlab::Ci::Reports::Security::FindingKey' do
    sequence :location_fingerprint do |a|
      Digest::SHA1.hexdigest(a.to_s)
    end
    sequence :identifier_fingerprint do |a|
      Digest::SHA1.hexdigest(a.to_s)
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::FindingKey.new(**attributes)
    end
  end
end
