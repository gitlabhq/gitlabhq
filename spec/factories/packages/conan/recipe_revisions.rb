# frozen_string_literal: true

FactoryBot.define do
  factory :conan_recipe_revision, class: 'Packages::Conan::RecipeRevision' do
    package { association(:conan_package) }
    association :project
    sequence(:revision) { |n| Digest::SHA1.hexdigest(n.to_s) } # rubocop:disable Fips/SHA1 -- The conan registry is not FIPS compliant
  end
end
