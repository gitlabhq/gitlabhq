# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    project
    author(factory: [:user, :with_namespace]) { project.creator }
    action { :joined }

    trait(:created)   { action { :created } }
    trait(:updated)   { action { :updated } }
    trait(:closed)    { action { :closed } }
    trait(:reopened)  { action { :reopened } }
    trait(:pushed)    { action { :pushed } }
    trait(:commented) { action { :commented } }
    trait(:merged)    { action { :merged } }
    trait(:joined)    { action { :joined } }
    trait(:left)      { action { :left } }
    trait(:destroyed) { action { :destroyed } }
    trait(:expired)   { action { :expired } }
    trait(:approved)  { action { :approved } }

    factory :closed_issue_event do
      action { :closed }
      target { association(:closed_issue, project: project) }
    end

    factory :wiki_page_event do
      action { :created }
      # rubocop: disable RSpec/FactoryBot/InlineAssociation
      # A persistent project is needed to have a wiki page being created properly.
      project { @overrides[:wiki_page]&.container || create(:project, :wiki_repo) }
      # rubocop: enable RSpec/FactoryBot/InlineAssociation
      target { association(:wiki_page_meta, :for_wiki_page, wiki_page: wiki_page) }

      transient do
        wiki_page { association(:wiki_page, container: project) }
      end
    end

    trait :for_wiki_page_note do
      action { :commented }
      # rubocop: disable RSpec/FactoryBot/InlineAssociation
      # A persistent project is needed to have a wiki page being created properly.
      project { @overrides[:wiki_page]&.container || create(:project, :wiki_repo) }
      # rubocop: enable RSpec/FactoryBot/InlineAssociation

      transient do
        wiki_page { association(:wiki_page, container: project) }
        wiki_page_meta { association(:wiki_page_meta, :for_wiki_page, wiki_page: wiki_page) }
        note { association(:note, author: author, project: project, noteable: wiki_page_meta) }
      end

      target { note }
    end

    trait :has_design do
      transient do
        design { association(:design, issue: association(:issue, project: project)) }
      end
    end

    trait :for_design do
      has_design

      transient do
        note { association(:note, author: author, project: project, noteable: design) }
      end

      action { :commented }
      target { note }
    end

    trait :for_issue do
      target { association(:issue) }
      target_type { 'Issue' }
    end

    trait :for_work_item do
      target { association(:work_item, :task) }
      target_type { 'WorkItem' }
    end

    trait :for_merge_request do
      target { association(:merge_request) }
      target_type { 'MergeRequest' }
    end

    factory :design_event, traits: [:has_design] do
      action { :created }
      target { design }
    end

    factory :design_updated_event, traits: [:has_design] do
      action { :updated }
      target { design }
    end

    factory :project_created_event do
      project factory: :project
      action { :created }
    end

    factory :project_imported_event do
      association :project, :with_import_url
      action { :created }
    end
  end

  factory :push_event, class: 'PushEvent' do
    project factory: :project_empty_repo
    author(factory: :user) { project.creator }
    action { :pushed }
  end

  factory :push_event_payload do
    event
    commit_count { 1 }
    action { :pushed }
    ref_type { :branch }
    ref { 'master' }
    commit_to { '3cdce97ed87c91368561584e7358f4d46e3e173c' }
  end
end
