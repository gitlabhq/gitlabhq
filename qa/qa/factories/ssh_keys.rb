# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/keys.html
    factory :ssh_key, class: 'QA::Resource::SSHKey'
  end
end
