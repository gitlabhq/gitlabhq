# frozen_string_literal: true

FactoryBot.define do
  factory :x509_commit_signature do
    commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    project
    x509_certificate
    verification_status { :verified }
  end
end
