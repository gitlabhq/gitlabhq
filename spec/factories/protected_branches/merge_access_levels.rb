FactoryGirl.define do
  factory :protected_branch_merge_access_level, class: ProtectedBranch::MergeAccessLevel do
    user nil
    protected_branch
    access_level { Gitlab::Access::DEVELOPER }
  end
end
