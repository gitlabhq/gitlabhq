FactoryGirl.define do
  factory :processed_lfs_ref do
    project
    ref 'feature_branch'
  end
end
