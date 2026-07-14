# frozen_string_literal: true

FactoryBot.define do
  factory :namespaces_consent, class: 'Namespaces::Consent' do
    association :namespace
    association :user
    feature_name { :code_review_flow_dap_routing }
  end
end
