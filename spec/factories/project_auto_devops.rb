FactoryBot.define do
  factory :project_auto_devops do
    project
    enabled true
    domain "example.com"
    deploy_strategy :continuous
  end
end
