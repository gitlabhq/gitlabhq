# frozen_string_literal: true

FactoryBot.define do
  factory :serverless_domain_cluster, class: '::Serverless::DomainCluster' do
    pages_domain { create(:pages_domain) }
    knative { create(:clusters_applications_knative) }
    creator { create(:user) }

    certificate do
      File.read(Rails.root.join('spec/fixtures/', 'ssl_certificate.pem'))
    end

    key do
      File.read(Rails.root.join('spec/fixtures/', 'ssl_key.pem'))
    end
  end
end
