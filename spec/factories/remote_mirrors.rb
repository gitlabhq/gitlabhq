# frozen_string_literal: true

FactoryBot.define do
  factory :remote_mirror, class: 'RemoteMirror' do
    association :project, :repository
    url "http://foo:bar@test.com"
  end
end
