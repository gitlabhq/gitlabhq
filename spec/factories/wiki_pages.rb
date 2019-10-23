# frozen_string_literal: true

require 'ostruct'

FactoryBot.define do
  factory :wiki_page do
    transient do
      attrs do
        {
          title: 'Title.with.dot',
          content: 'Content for wiki page',
          format: 'markdown'
        }
      end
    end

    page { OpenStruct.new(url_path: 'some-name') }
    association :wiki, factory: :project_wiki, strategy: :build
    initialize_with { new(wiki, page, true) }

    before(:create) do |wiki_page, evaluator|
      wiki_page.attributes = evaluator.attrs.with_indifferent_access
    end

    to_create do |wiki_page|
      wiki_page.create
    end
  end
end
