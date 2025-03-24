# frozen_string_literal: true

FactoryBot.define do
  factory :conan_recipe_revision, class: 'Packages::Conan::RecipeRevision' do
    package do
      association(:conan_package, without_recipe_revisions: true, without_package_files: true)
    end
    project { package.project }
    sequence(:revision) { |n| Digest::SHA1.hexdigest(n.to_s) } # rubocop:disable Fips/SHA1 -- The conan registry is not FIPS compliant
  end
end
