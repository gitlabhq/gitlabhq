# frozen_string_literal: true

FactoryBot.define do
  factory :wiki_page do
    transient do
      title { generate(:wiki_page_title) }
      content { 'Content for wiki page' }
      format { :markdown }
      message { nil }
      project { association(:project) }
      container { project }
      wiki { association(:wiki, container: container) }
      page { ActiveSupport::InheritableOptions.new(url_path: title) }
    end

    initialize_with do
      new(wiki, page).tap do |page|
        page.attributes = {
          slug: title&.tr(' ', '-'),
          title: title,
          content: content,
          format: format
        }
      end
    end

    # Clear our default @page, except when using build_stubbed
    after(:build) do |page|
      page.instance_variable_set(:@page, nil)
    end

    to_create do |page, evaluator|
      # WikiPages is ActiveModel which doesn't support `create!`.
      page.create(message: evaluator.message) # rubocop:disable Rails/SaveBang
    end
  end

  factory :wiki_page_meta, class: 'WikiPage::Meta' do
    title { generate(:wiki_page_title) }
    container do
      @overrides[:wiki_page]&.container ||
        @overrides[:project] ||
        @overrides[:namespace] ||
        association(:project)
    end

    trait :for_wiki_page do
      wiki_page { association(:wiki_page, container: container) }
      title { wiki_page.title }

      initialize_with do
        raise 'Metadata only available for valid pages' unless wiki_page.valid?

        WikiPage::Meta.find_or_create(wiki_page.slug, wiki_page)
      end
    end
  end

  factory :wiki_page_slug, class: 'WikiPage::Slug' do
    wiki_page_meta { association(:wiki_page_meta) }
    slug { generate(:sluggified_title) }
    canonical { false }

    trait :canonical do
      canonical { true }
    end
  end

  sequence(:wiki_page_title) { |n| "Page #{n}" }
  sequence(:wiki_filename) { |n| "Page_#{n}.md" }
  sequence(:sluggified_title) { |n| "slug-#{n}" }
end
