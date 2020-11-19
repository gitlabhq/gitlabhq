# frozen_string_literal: true

FactoryBot.define do
  factory :serverless_domain, class: '::Serverless::Domain' do
    function_name { 'test-function' }
    serverless_domain_cluster { association(:serverless_domain_cluster) }
    environment { association(:environment) }

    skip_create
  end
end
