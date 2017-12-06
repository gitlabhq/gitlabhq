# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :appearance do
    title "GitLab Enterprise Edition"
    description "Open source software to collaborate on code"
    new_project_guidelines "Custom project guidelines"
  end
end
