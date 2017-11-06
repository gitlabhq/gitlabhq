FactoryGirl.define do
  factory :unprocessed_lfs_push do
    project
    ref 'feature_branch'
  end
end
