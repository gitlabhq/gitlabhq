FactoryGirl.define do
  factory :protected_branch_push_access_level, class: ProtectedBranch::PushAccessLevel do
    user nil
    protected_branch
    access_level { Gitlab::Access::MASTER }
  end
end
