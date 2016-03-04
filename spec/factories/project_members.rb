FactoryGirl.define do
  factory :project_member do
    user
    project
    access_level { ProjectMember::MASTER }
  end
end
