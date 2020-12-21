# frozen_string_literal: true

FactoryBot.define do
  factory :debian_file_metadatum, class: 'Packages::Debian::FileMetadatum' do
    package_file { association(:debian_package_file, without_loaded_metadatum: true) }
    file_type { 'deb' }
    component { 'main' }
    architecture { 'amd64' }
    fields { { 'a': 'b' } }

    trait(:unknown) do
      file_type { 'unknown' }
      component { nil }
      architecture { nil }
      fields { nil }
    end

    trait(:source) do
      file_type { 'source' }
      component { 'main' }
      architecture { nil }
      fields { nil }
    end

    trait(:dsc) do
      file_type { 'dsc' }
      component { 'main' }
      architecture { nil }
      fields { { 'a': 'b' } }
    end

    trait(:deb) do
      file_type { 'deb' }
      component { 'main' }
      architecture { 'amd64' }
      fields { { 'a': 'b' } }
    end

    trait(:udeb) do
      file_type { 'udeb' }
      component { 'main' }
      architecture { 'amd64' }
      fields { { 'a': 'b' } }
    end

    trait(:buildinfo) do
      file_type { 'buildinfo' }
      component { 'main' }
      architecture { nil }
      fields { { 'Architecture': 'amd64 source' } }
    end

    trait(:changes) do
      file_type { 'changes' }
      component { nil }
      architecture { nil }
      fields { { 'Architecture': 'source amd64' } }
    end
  end
end
