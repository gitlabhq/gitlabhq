# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_commit_email, class: 'Users::NamespaceCommitEmail' do
    email
    user { email.user }
    namespace
  end
end
