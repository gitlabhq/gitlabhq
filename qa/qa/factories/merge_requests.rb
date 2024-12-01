# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :merge_request, class: 'QA::Resource::MergeRequest' do
      trait :no_preparation do
        no_preparation { true }
      end
    end

    factory :merge_request_from_fork, class: 'QA::Resource::MergeRequestFromFork'
  end
end
