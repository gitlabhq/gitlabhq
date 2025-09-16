# frozen_string_literal: true

FactoryBot.define do
  factory :remote_mirror, class: 'RemoteMirror' do
    association :project, :repository
    url { "http://foo:bar@test.com" }

    trait :ssh do
      url { 'ssh://git@test.com:foo/bar.git' }
      auth_method { 'ssh_public_key' }
    end

    trait :host_keys do
      ssh_known_hosts do
        <<~KEY.delete("\n")
          gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGje
          R4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
        KEY
      end
    end
  end
end
