# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/packages.html
    factory :package, class: 'QA::Resource::Package'
  end
end
