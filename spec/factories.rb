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
    password "12345678"
    password_confirmation { password }
    confirmed_at { Time.now }
    confirmation_token { nil }

    trait :admin do
      admin true
    end

    factory :admin, traits: [:admin]
  end

  factory :group do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
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

    factory :another_key do
      key do
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmTillFzNTrrGgwaCKaSj+QCz81E6jBc/s9av0+3b1Hwfxgkqjl4nAK/OD2NjgyrONDTDfR8cRN4eAAy6nY8GLkOyYBDyuc5nTMqs5z3yVuTwf3koGm/YQQCmo91psZ2BgDFTor8SVEE5Mm1D1k3JDMhDFxzzrOtRYFPci9lskTJaBjpqWZ4E9rDTD2q/QZntCqbC3wE9uSemRQB5f8kik7vD/AD8VQXuzKladrZKkzkONCPWsXDspUitjM8HkQdOf0PsYn1CMUC1xKYbCxkg5TkEosIwGv6CoEArUrdu/4+10LVslq494mAvEItywzrluCLCnwELfW+h/m8UHoVhZ"
      end
    end

    factory :invalid_key do
      key do
        "ssh-rsa this_is_invalid_key=="
      end
    end
  end

  factory :email do
    user
    email do
      Faker::Internet.email('alias')
    end

    factory :another_email do
      email do
        Faker::Internet.email('another.alias')
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
