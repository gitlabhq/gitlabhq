# frozen_string_literal: true

FactoryBot.define do
  factory :composer_metadatum, class: 'Packages::Composer::Metadatum' do
    package { association(:composer_package) }

    target_sha { '123' }
    composer_json { { name: 'foo' } }
  end
end
