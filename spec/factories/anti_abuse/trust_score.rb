# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_trust_score, class: 'AntiAbuse::TrustScore' do
    user
    score { 0.1 }
    source { :spamcheck }
    correlation_id_value { 'abcdefg' }
  end
end
