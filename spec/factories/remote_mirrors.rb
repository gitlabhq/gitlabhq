# frozen_string_literal: true

FactoryBot.define do
  factory :remote_mirror, class: 'RemoteMirror' do
    association :project, :repository
    url { "http://foo:bar@test.com" }

    trait :ssh do
      url { 'ssh://git@test.com:foo/bar.git' }
      auth_method { 'ssh_public_key' }
    end
  end
end
