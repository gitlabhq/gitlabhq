FactoryBot.define do
  factory :release do
    tag "v1.1.0"
    sha 'b83d6e391c22777fca1ed3012fce84f633d7fed0'
    name { tag }
    description "Awesome release"
    project
    author

    trait :legacy do
      sha nil
      author nil
    end
  end
end
