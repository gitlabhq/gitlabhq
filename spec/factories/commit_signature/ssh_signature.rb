# frozen_string_literal: true

FactoryBot.define do
  factory :ssh_signature, class: 'CommitSignatures::SshSignature' do
    commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    project
    key
    verification_status { :verified }
  end
end
