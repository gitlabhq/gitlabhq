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
    username { Faker::Internet.user_name }
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
    owner
  end

  factory :group do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    owner
    type 'Group'
  end

  factory :namespace do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    owner
  end

  factory :users_project do
    user
    project
    project_access { UsersProject::MASTER }
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

    trait :closed do
      closed true
    end

    # pick 3 commits "at random" (from bcf03b5d~3 to bcf03b5d)
    trait :with_diffs do
      target_branch "bcf03b5d~3"
      source_branch "bcf03b5d"
      st_commits do
        [Commit.new(project.repo.commit('bcf03b5d')),
         Commit.new(project.repo.commit('bcf03b5d~1')),
         Commit.new(project.repo.commit('bcf03b5d~2'))]
      end
      st_diffs do
        project.repo.diff("bcf03b5d~3", "bcf03b5d")
      end
    end

    factory :closed_merge_request, traits: [:closed]
    factory :merge_request_with_diffs, traits: [:with_diffs]
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
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
    end

    factory :deploy_key do
      project
    end

    factory :personal_key do
      user
    end

    factory :key_with_a_space_in_the_middle do
      key do
        "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa ++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
      end
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

  factory :service do
    type ""
    title "GitLab CI"
    token "x56olispAND34ng"
    project
  end

  factory :service_hook do
    url
    service
  end
end
