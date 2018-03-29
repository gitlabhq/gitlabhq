FactoryBot.define do
  factory :repository_state, class: 'ProjectRepositoryState' do
    project

    trait :repository_failed do
      repository_verification_checksum nil
      last_repository_verification_failure 'Could not calculate the checksum'
    end

    trait :repository_outdated do
      repository_verification_checksum nil
      last_repository_verification_failure nil
    end

    trait :repository_verified do
      repository_verification_checksum 'f079a831cab27bcda7d81cd9b48296d0c3dd92ee'
      last_repository_verification_failure nil
    end

    trait :wiki_failed do
      wiki_verification_checksum nil
      last_wiki_verification_failure 'Could not calculate the checksum'
    end

    trait :wiki_outdated do
      wiki_verification_checksum nil
      last_wiki_verification_failure nil
    end

    trait :wiki_verified do
      wiki_verification_checksum 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef'
      last_wiki_verification_failure nil
    end
  end
end
