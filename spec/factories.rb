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

  factory :empty_project, class: 'Project' do
    sequence(:name) { |n| "project#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    namespace
    creator
  end

  factory :project, parent: :empty_project do
    path { 'gitlabhq' }

    after :create do |project|
      TestEnv.clear_repo_dir(project.namespace, project.path)
      TestEnv.reset_satellite_dir
      TestEnv.create_repo(project.namespace, project.path)
    end
  end

  factory :redmine_project, parent: :project do
    issues_tracker { "redmine" }
    issues_tracker_id { "project_name_in_redmine" }
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

  factory :merge_request do
    title
    author
    source_project factory: :project
    target_project { source_project }

    # → git log stable..master --pretty=oneline
    # b1e6a9dbf1c85e6616497a5e7bad9143a4bd0828 tree css fixes
    # 8716fc78f3c65bbf7bcf7b574febd583bc5d2812 Added loading animation  for notes
    # cd5c4bac5042c5469dcdf7e7b2f768d3c6fd7088 notes count for wall
    # 8470d70da67355c9c009e4401746b1d5410af2e3 notes controller refactored
    # 1e689bfba39525ead225eaf611948cfbe8ac34cf fixed notes logic
    # f0f14c8eaba69ebddd766498a9d0b0e79becd633 finished scss refactoring
    # 3a4b4fb4cde7809f033822a171b9feae19d41fff Moving ui styles to one scss file, Added ui class to body
    # 065c200c33f68c2bb781e35a43f9dc8138a893b5 removed unnecessary hr tags & titles
    # 1e8b111be85df0db6c8000ef9a710bc0221eae83 Merge branch 'master' of github.com:gitlabhq/gitlabhq
    # f403da73f5e62794a0447aca879360494b08f678 Fixed ajax loading image. Fixed wrong wording
    # e6ea73c77600d413d370249b8e392734f7d1dbee Merge pull request #468 from bencevans/patch-1
    # 4a3c05b69355deee25767a74d0512ec4b510d4ef Merge pull request #470 from bgondy/patch-1
    # 0347fe2412eb51d3efeccc35210e9268bc765ac5 Update app/views/projects/team.html.haml
    # 2b5c61bdece1f7eb2b901ceea7d364065cdf76ac Title for a link fixed
    # 460eeb13b7560b40104044973ff933b1a6dbbcaa Increased count of notes loaded when visit wall page
    # 21c141afb1c53a9180a99d2cca29ffa613eb7e3a Merge branch 'notes_refactoring'
    # 292a41cbe295f16f7148913b31eb0fb91f3251c3 Fixed comments for snippets. Tests fixed
    # d41d8ffb02fa74fd4571603548bd7e401ec99e0c Reply button, Comments for Merge Request diff
    # b1a36b552be2a7a6bc57fbed6c52dc6ed82111f8 Merge pull request #466 from skroutz/no-rbenv
    # db75dae913e8365453ca231f101b067314a7ea71 Merge pull request #465 from skroutz/branches_commit_link
    # 75f040fbfe4b5af23ff004ad3207c3976df097a8 Don't enforce rbenv version
    # e42fb4fda475370dcb0d8f8f1268bfdc7a0cc437 Fix broken commit link in branches page
    # 215a01f63ccdc085f75a48f6f7ab6f2b15b5852c move notes login to one controller
    # 81092c01984a481e312de10a28e3f1a6dda182a3 Status codes for errors, New error pages
    # 7d279f9302151e3c8f4c5df9c5200a72799409b9 better error handling for not found resource, gitolite error
    # 9e6d0710e927aa8ea834b8a9ae9f277be617ac7d Merge pull request #443 from CedricGatay/fix/incorrectLineNumberingInDiff
    # 6ea87c47f0f8a24ae031c3fff17bc913889ecd00 Incorrect line numbering in diff
    #
    # → git log master..stable --pretty=oneline
    # empty

    source_branch "master"
    target_branch "stable"

    trait :with_diffs do
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
      project factory: :project
      commit_id "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a"
      noteable_type "Commit"
    end

    trait :on_diff do
      line_code "0_184_184"
    end

    trait :on_merge_request do
      project factory: :project
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
