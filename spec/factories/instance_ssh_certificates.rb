# frozen_string_literal: true

FactoryBot.define do
  factory :instance_ssh_certificate, class: 'InstanceSshCertificate' do
    title

    key do
      SSHData::PrivateKey::RSA.generate(
        ::Gitlab::SSHPublicKey.supported_sizes(:rsa).min, unsafe_allow_small_key: true
      ).public_key.openssh(comment: 'dummy@gitlab.com')
    end

    fingerprint do
      Gitlab::SSHPublicKey.new(key).fingerprint_sha256.delete_prefix('SHA256:')
    end
  end
end
