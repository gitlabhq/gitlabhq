FactoryGirl.define do
  factory :merge_request do
    title
    author
    source_project factory: :project
    target_project { source_project }

    # → git log --pretty=oneline feature..master
    # 5937ac0a7beb003549fc5fd26fc247adbce4a52e Add submodule from gitlab.com
    # 570e7b2abdd848b95f2f578043fc23bd6f6fd24d Change some files
    # 6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9 More submodules
    # d14d6c0abdd253381df51a723d58691b2ee1ab08 Remove ds_store files
    # c1acaa58bbcbc3eafe538cb8274ba387047b69f8 Ignore DS files
    #
    # See also RepoHelpers.sample_compare
    #
    source_branch "master"
    target_branch "feature"

    merge_status :can_be_merged

    trait :with_diffs do
    end

    trait :conflict do
      source_branch "feature_conflict"
      target_branch "feature"
    end

    trait :closed do
      state :closed
    end

    trait :reopened do
      state :reopened
    end

    trait :simple do
      source_branch "feature"
      target_branch "master"
    end

    factory :closed_merge_request, traits: [:closed]
    factory :reopened_merge_request, traits: [:reopened]
    factory :merge_request_with_diffs, traits: [:with_diffs]
  end
end
