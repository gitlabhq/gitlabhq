require_relative '../support/test_env'

FactoryGirl.define do
  factory :remote_mirror, class: 'RemoteMirror' do
    association :project, :repository
    url "http://foo:bar@test.com"
  end
end
