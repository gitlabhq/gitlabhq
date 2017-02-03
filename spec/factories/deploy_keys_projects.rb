FactoryGirl.define do
  factory :deploy_keys_project do
    deploy_key
    project factory: :empty_project
  end
end
