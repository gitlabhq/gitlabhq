# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/pipelines.html
    factory :pipeline, class: 'QA::Resource::Pipeline'
  end
end
