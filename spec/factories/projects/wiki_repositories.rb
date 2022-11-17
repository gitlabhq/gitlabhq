# frozen_string_literal: true

FactoryBot.define do
  factory :project_wiki_repository, class: 'Projects::WikiRepository' do
    project
  end
end
