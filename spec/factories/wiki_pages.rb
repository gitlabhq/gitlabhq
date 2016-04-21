require 'ostruct'

FactoryGirl.define do
  factory :wiki_page do
    page = OpenStruct.new(url_path: 'some-name')
    association :wiki, factory: :project_wiki, strategy: :build
    initialize_with { new(wiki, page, true) }
  end
end
