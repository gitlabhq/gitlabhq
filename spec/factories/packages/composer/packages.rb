# frozen_string_literal: true

FactoryBot.define do
  factory :composer_package, class: 'Packages::Composer::Package', parent: :package do
    sequence(:name) { |n| "composer-package-#{n}" }
    sequence(:version) { |n| "1.0.#{n}" }

    target_sha do
      project&.repository&.find_branch('master')&.target || OpenSSL::Digest.hexdigest('SHA1', SecureRandom.hex)
    rescue Gitlab::Git::Repository::NoRepository
      OpenSSL::Digest.hexdigest('SHA1', SecureRandom.hex)
    end

    composer_json { { name: name, version: version } }
  end
end
