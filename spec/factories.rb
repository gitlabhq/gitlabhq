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
  def self.attributes(type, *args)
    FactoryGirl.attributes_for(type, *args)
  end
end

FactoryGirl.define do
  sequence :sentence, aliases: [:title, :content] do
    Faker::Lorem.sentence
  end

  sequence :name, aliases: [:file_name] do
    Faker::Name.name
  end

  sequence(:url) { Faker::Internet.uri('http') }

  factory :user, aliases: [:author, :assignee, :owner] do
    email { Faker::Internet.email }
    name
    password "123456"
    password_confirmation { password }

    trait :admin do
      admin true
    end

    factory :admin, traits: [:admin]
  end

  factory :project do
    sequence(:name) { |n| "project#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    code { name.downcase.gsub(/\s/, '_') }
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
    factory :closed_issue_event do
      project
      action Event::Closed
      target factory: :closed_issue
      author factory: :user
    end
  end

  factory :key do
    title
    key do
      """
      ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4
      596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4
      soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=
      """
    end

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
    file_name
  end

  factory :protected_branch do
    name
    project
  end
end
