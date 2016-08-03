FactoryGirl.define do
  factory :environment, class: Environment do
    sequence(:name) { |n| "environment#{n}" }

    project factory: :empty_project
    sequence(:external_url) { |n| "https://env#{n}.example.gitlab.com" }
  end
end
