include ActionDispatch::TestProcess

FactoryGirl.define do
  sequence :sentence, aliases: [:title, :content] do
    Faker::Lorem.sentence
  end

  sequence :name, aliases: [:file_name] do
    Faker::Name.name
  end

  sequence(:url) { Faker::Internet.uri('http') }

  factory :user, aliases: [:author, :assignee, :owner, :creator] do
    email { Faker::Internet.email }
    name
    sequence(:username) { |n| "#{Faker::Internet.user_name}#{n}" }
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
    creator

    trait :source do
      sequence(:name) { |n| "source project#{n}" }
    end
    trait :target do
      sequence(:name) { |n| "target project#{n}" }
    end

    factory :source_project, traits: [:source]
    factory :target_project, traits: [:target]
  end


  factory :redmine_project, parent: :project do
    issues_tracker { "redmine" }
    issues_tracker_id { "project_name_in_redmine" }
  end

  factory :project_with_code, parent: :project do
    path { 'gitlabhq' }

    trait :source_path do
      path { 'source_gitlabhq' }
    end

    trait :target_path do
      path { 'target_gitlabhq' }
    end

    factory :source_project_with_code, traits: [:source, :source_path]
    factory :target_project_with_code, traits: [:target, :target_path]

    after :create do |project|
      TestEnv.clear_repo_dir(project.namespace, project.path)
      TestEnv.create_repo(project.namespace, project.path)
    end
  end

  factory :group do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    owner
    type 'Group'
  end

  factory :namespace do
    sequence(:name) { |n| "namespace#{n}" }
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
      state :closed
    end

    trait :reopened do
      state :reopened
    end

    factory :closed_issue, traits: [:closed]
    factory :reopened_issue, traits: [:reopened]
  end

  factory :merge_request do
    title
    author
    source_project factory: :source_project_with_code
    target_project factory: :target_project_with_code
    source_branch "master"
    target_branch "stable"

    # pick 3 commits "at random" (from bcf03b5d~3 to bcf03b5d)
    trait :with_diffs do
      target_branch "master" # pretend bcf03b5d~3
      source_branch "stable" # pretend bcf03b5d
      st_commits do
        [
          source_project.repository.commit('bcf03b5d').to_hash,
          source_project.repository.commit('bcf03b5d~1').to_hash,
          source_project.repository.commit('bcf03b5d~2').to_hash
        ]
      end
      st_diffs do
        source_project.repo.diff("bcf03b5d~3", "bcf03b5d")
      end
    end

    trait :closed do
      state :closed
    end

    trait :reopened do
      state :reopened
    end

    factory :closed_merge_request, traits: [:closed]
    factory :reopened_merge_request, traits: [:reopened]
    factory :merge_request_with_diffs, traits: [:with_diffs]
  end

  factory :note do
    project
    note "Note"
    author

    factory :note_on_commit, traits: [:on_commit]
    factory :note_on_commit_diff, traits: [:on_commit, :on_diff]
    factory :note_on_issue, traits: [:on_issue], aliases: [:votable_note]
    factory :note_on_merge_request, traits: [:on_merge_request]
    factory :note_on_merge_request_diff, traits: [:on_merge_request, :on_diff]
    factory :note_on_merge_request_with_attachment, traits: [:on_merge_request, :with_attachment]

    trait :on_commit do
      project factory: :project_with_code
      commit_id "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a"
      noteable_type "Commit"
    end

    trait :on_diff do
      line_code "0_184_184"
    end

    trait :on_merge_request do
      project factory: :project_with_code
      noteable_id 1
      noteable_type "MergeRequest"
    end

    trait :on_issue do
      noteable_id 1
      noteable_type "Issue"
    end

    trait :with_attachment do
      attachment { fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png") }
    end
  end

  factory :event do
    factory :closed_issue_event do
      project
      action { Event::CLOSED }
      target factory: :closed_issue
      author factory: :user
    end
  end

  factory :key do
    title
    key do
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
    end

    factory :deploy_key, class: 'DeployKey' do
    end

    factory :personal_key do
      user
    end

    factory :key_with_a_space_in_the_middle do
      key do
        "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa ++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
      end
    end

    factory :invalid_key do
      key do
        "ssh-rsa this_is_invalid_key=="
      end
    end
  end

  factory :milestone do
    title
    project

    trait :closed do
      state :closed
    end

    factory :closed_milestone, traits: [:closed]
  end

  factory :system_hook do
    url
  end

  factory :project_hook do
    url
  end

  factory :project_snippet do
    project
    author
    title
    content
    file_name
  end

  factory :personal_snippet do
    author
    title
    content
    file_name
  end

  factory :snippet do
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

  factory :deploy_keys_project do
    deploy_key
    project
  end
end
