# frozen_string_literal: true

FactoryBot.define do
  factory :tag_gpg_signature, class: 'Repositories::Tags::GpgSignature' do
    object_name { Digest::SHA256.hexdigest(SecureRandom.hex) }
    project
    gpg_key
    gpg_key_primary_keyid { gpg_key.keyid }
    verification_status { :verified }
  end
end
