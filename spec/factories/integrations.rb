FactoryGirl.define do
  factory :integration, class: Integration do
    sequence(:name) { |n| "integration#{n}" }

    project factory: :empty_project
    external_token { ('a'..'z').to_a.shuffle.join }
  end
end
