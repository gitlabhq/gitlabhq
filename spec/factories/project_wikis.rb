# frozen_string_literal: true

FactoryBot.define do
  factory :project_wiki do
    skip_create

    association :project, :wiki_repo
    user { project.creator }
    initialize_with { new(project, user) }
  end
end
