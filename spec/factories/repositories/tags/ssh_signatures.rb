# frozen_string_literal: true

FactoryBot.define do
  factory :tag_ssh_signature, class: 'Repositories::Tags::SshSignature' do
    object_name { Digest::SHA256.hexdigest(SecureRandom.hex) }
    project
    verification_status { :verified }
  end
end
