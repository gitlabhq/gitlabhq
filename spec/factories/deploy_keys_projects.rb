FactoryGirl.define do
  factory :deploy_keys_project do
    deploy_key
    project
  end
end
