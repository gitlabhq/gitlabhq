# frozen_string_literal: true

FactoryBot.define do
  factory :cargo_metadatum, class: 'Packages::Cargo::Metadatum' do
    package { association(:cargo_package) }
    project { package.project }

    normalized_name { package.name&.downcase&.tr('_', '-') }
    normalized_version { package.version&.sub(/\+.*\z/, '') }

    index_content do
      {
        name: package.name,
        deps: [
          {
            name: "dep_1",
            req: "^0.6"
          }
        ],
        vers: "0.1.0",
        cksum: "1234567890",
        v: 2
      }
    end
  end
end
