FactoryBot.define do
  factory :repository_state, class: 'ProjectRepositoryState' do
    project

    trait :repository_outdated do
      repository_verification_checksum    'f079a831cab27bcda7d81cd9b48296d0c3dd92ee'
      last_repository_verification_at     { 5.days.ago }
      last_repository_verification_failed false
    end

    trait :repository_verified do
      repository_verification_checksum    'f079a831cab27bcda7d81cd9b48296d0c3dd92ee'
      last_repository_verification_failed false
      last_repository_verification_at     { Time.now }
    end

    trait :wiki_outdated do
      repository_verification_checksum    'f079a831cab27bcda7d81cd9b48296d0c3dd92ee'
      last_repository_verification_at     { 5.days.ago }
      last_repository_verification_failed false
    end

    trait :wiki_verified do
      wiki_verification_checksum    'e079a831cab27bcda7d81cd9b48296d0c3dd92ef'
      last_wiki_verification_failed false
      last_wiki_verification_at     { Time.now }
    end
  end
end
