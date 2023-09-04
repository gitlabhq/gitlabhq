# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/jobs.html
    factory :job, class: 'QA::Resource::Job'
  end
end
