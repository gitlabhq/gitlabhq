FactoryBot.define do
  factory :protected_branch_unprotect_access_level, class: ProtectedBranch::UnprotectAccessLevel do
    user nil
    group nil
    protected_branch
    access_level { Gitlab::Access::DEVELOPER }
  end
end
