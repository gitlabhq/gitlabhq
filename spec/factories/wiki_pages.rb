require 'ostruct'

FactoryBot.define do
  factory :wiki_page do
    transient do
      attrs do
        {
          title: 'Title',
          content: 'Content for wiki page',
          format: 'markdown'
        }
      end
    end

    page { OpenStruct.new(url_path: 'some-name') }
    association :wiki, factory: :project_wiki, strategy: :build
    initialize_with { new(wiki, page, true) }

    before(:create) do |page, evaluator|
      page.attributes = evaluator.attrs
    end

    to_create do |page|
      page.create
    end
  end
end
