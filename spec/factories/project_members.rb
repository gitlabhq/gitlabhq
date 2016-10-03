FactoryGirl.define do
  factory :project_member do
    user
    project
    master

    trait(:guest)     { access_level ProjectMember::GUEST }
    trait(:reporter)  { access_level ProjectMember::REPORTER }
    trait(:developer) { access_level ProjectMember::DEVELOPER }
    trait(:master)    { access_level ProjectMember::MASTER }
  end
end
