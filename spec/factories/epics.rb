FactoryBot.define do
  factory :epic do
    title { generate(:title) }
    group
    author
  end
end
