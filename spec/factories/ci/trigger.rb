FactoryGirl.define do
  factory :ci_trigger, class: Ci::Trigger do
    owner factory: :user
    project factory: :empty_project
  end
end
