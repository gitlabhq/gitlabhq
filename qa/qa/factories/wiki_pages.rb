# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :project_wiki_page, class: 'QA::Resource::Wiki::ProjectPage'
    factory :group_wiki_page, class: 'QA::Resource::Wiki::GroupPage'
  end
end
