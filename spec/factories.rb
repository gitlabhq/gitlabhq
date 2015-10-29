include ActionDispatch::TestProcess

FactoryGirl.define do
  sequence :sentence, aliases: [:title, :content] do
    FFaker::Lorem.sentence
  end

  sequence :name do
    FFaker::Name.name
  end

  sequence :file_name do
    FFaker::Internet.user_name
  end

  sequence(:url) { FFaker::Internet.uri('http') }

  factory :user, aliases: [:author, :assignee, :owner, :creator] do
    email { FFaker::Internet.email }
    name
    sequence(:username) { |n| "#{FFaker::Internet.user_name}#{n}" }
    password "12345678"
    confirmed_at { Time.now }
    confirmation_token { nil }
    can_create_group true

    trait :admin do
      admin true
    end

    trait :two_factor do
      before(:create) do |user|
        user.two_factor_enabled = true
        user.otp_secret = User.generate_otp_secret(32)
        user.generate_otp_backup_codes!
      end
    end

    factory :omniauth_user do
      ignore do
        extern_uid '123456'
        provider 'ldapmain'
      end

      after(:create) do |user, evaluator|
        user.identities << create(:identity,
          provider: evaluator.provider,
          extern_uid: evaluator.extern_uid
        )
      end
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

  factory :project_member do
    user
    project
    access_level { ProjectMember::MASTER }
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
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0= dummy@gitlab.com"
    end

    factory :deploy_key, class: 'DeployKey' do
    end

    factory :personal_key do
      user
    end

    factory :another_key do
      key do
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmTillFzNTrrGgwaCKaSj+QCz81E6jBc/s9av0+3b1Hwfxgkqjl4nAK/OD2NjgyrONDTDfR8cRN4eAAy6nY8GLkOyYBDyuc5nTMqs5z3yVuTwf3koGm/YQQCmo91psZ2BgDFTor8SVEE5Mm1D1k3JDMhDFxzzrOtRYFPci9lskTJaBjpqWZ4E9rDTD2q/QZntCqbC3wE9uSemRQB5f8kik7vD/AD8VQXuzKladrZKkzkONCPWsXDspUitjM8HkQdOf0PsYn1CMUC1xKYbCxkg5TkEosIwGv6CoEArUrdu/4+10LVslq494mAvEItywzrluCLCnwELfW+h/m8UHoVhZ"
      end

      factory :another_deploy_key, class: 'DeployKey' do
      end
    end
  end

  factory :email do
    user
    email do
      FFaker::Internet.email('alias')
    end

    factory :another_email do
      email do
        FFaker::Internet.email('another.alias')
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

    trait :public do
      visibility_level Gitlab::VisibilityLevel::PUBLIC
    end

    trait :internal do
      visibility_level Gitlab::VisibilityLevel::INTERNAL
    end

    trait :private do
      visibility_level Gitlab::VisibilityLevel::PRIVATE
    end
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

  factory :identity do
    provider 'ldapmain'
    extern_uid 'my-ldap-id'
  end
end
