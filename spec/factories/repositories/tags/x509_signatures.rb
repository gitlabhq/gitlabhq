# frozen_string_literal: true

FactoryBot.define do
  factory :tag_x509_signature, class: 'Repositories::Tags::X509Signature' do
    object_name { Digest::SHA256.hexdigest(SecureRandom.hex) }
    project
    x509_certificate
    verification_status { :verified }
  end
end
