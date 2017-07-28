FactoryGirl.define do
  factory :geo_file_registry, class: Geo::FileRegistry do
    sequence(:file_id)
    file_type :file
    bytes nil
    sha256 nil

    trait :avatar do
      file_type :avatar
    end

    trait :lfs do
      file_type :lfs
    end
  end
end
