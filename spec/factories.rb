# Backwards compatibility with the old method
def Factory(type, *args)
  FactoryGirl.create(type, *args)
end

module Factory
  def self.create(type, *args)
    FactoryGirl.create(type, *args)
  end

  def self.new(type, *args)
    FactoryGirl.build(type, *args)
  end
end

FactoryGirl.define do
  sequence :sentence, aliases: [:title, :content] do
    Faker::Lorem.sentence
  end

  sequence(:url) { Faker::Internet.uri('http') }

  factory :user, aliases: [:author, :assignee, :owner] do
    email { Faker::Internet.email }
    name  { Faker::Name.name }
    password "123456"
    password_confirmation "123456"

    trait :admin do
      admin true
    end

    factory :admin, traits: [:admin]
  end

  factory :project do
    sequence(:name) { |n| "project#{n}" }
    path { name }
    code { name }
    owner
  end

  factory :users_project do
    user
    project
  end

  factory :issue do
    title
    author
    project

    trait :closed do
      closed true
    end

    factory :closed_issue, traits: [:closed]
  end

  factory :merge_request do
    title
    author
    project
    source_branch "master"
    target_branch "stable"
  end

  factory :note do
    project
    note "Note"
  end

  factory :event do
  end

  factory :key do
    title
    key { File.read(File.join(Rails.root, "db", "pkey.example")) }

    factory :deploy_key do
      project
    end

    factory :personal_key do
      user
    end
  end

  factory :milestone do
    title
    project
  end

  factory :system_hook do
    url
  end

  factory :project_hook do
    url
  end

  factory :wiki do
    title
    content
    user
  end

  factory :snippet do
    project
    author
    title
    content
    file_name { Faker::Lorem.sentence }
  end
end
