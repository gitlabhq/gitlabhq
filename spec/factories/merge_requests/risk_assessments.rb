# frozen_string_literal: true

FactoryBot.define do
  factory :merge_requests_risk_assessment, class: 'MergeRequests::RiskAssessment' do
    association :merge_request
    project_id { merge_request.target_project_id }
    diff_sha { Digest::SHA1.hexdigest(SecureRandom.hex) } # rubocop:disable Fips/SHA1 -- test data
  end
end
