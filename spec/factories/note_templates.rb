FactoryGirl.define do
  factory :note_template do
    title { FFaker::BaconIpsum.characters(25) }
    note { FFaker::BaconIpsum.characters(100) }
    user
  end
end
