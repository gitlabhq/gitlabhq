# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :snippet, class: 'QA::Resource::Snippet' do
      trait :private do
        visibility { 'Private' }
      end

      factory :project_snippet, class: 'QA::Resource::ProjectSnippet'
    end
  end
end
