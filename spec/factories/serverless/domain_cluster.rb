# frozen_string_literal: true

FactoryBot.define do
  factory :serverless_domain_cluster, class: '::Serverless::DomainCluster' do
    pages_domain { association(:pages_domain) }
    knative { association(:clusters_applications_knative) }
    creator { association(:user) }

    certificate do
      File.read(Rails.root.join('spec/fixtures/', 'ssl_certificate.pem'))
    end

    key do
      File.read(Rails.root.join('spec/fixtures/', 'ssl_key.pem'))
    end
  end
end
