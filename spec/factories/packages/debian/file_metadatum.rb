# frozen_string_literal: true

FactoryBot.define do
  factory :debian_file_metadatum, class: 'Packages::Debian::FileMetadatum' do
    package_file do
      if file_type == 'unknown'
        association(:debian_package_file, :unknown, without_loaded_metadatum: true)
      else
        association(:debian_package_file, without_loaded_metadatum: true)
      end
    end

    file_type { 'deb' }
    component { 'main' }
    architecture { 'amd64' }
    fields { { 'a' => 'b' } }

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
      fields do
        {
          'Format' => '3.0 (native)',
          'Source' => package_file.package.name,
          'Binary' => 'sample-dev, libsample0, sample-udeb, sample-ddeb',
          'Architecture' => 'any',
          'Version' => package_file.package.version,
          'Maintainer' => "#{FFaker::Name.name} <#{FFaker::Internet.email}>",
          'Homepage' => FFaker::Internet.http_url,
          'Standards-Version' => '4.5.0',
          'Build-Depends' => 'debhelper-compat (= 13)',
          'Package-List' => <<~PACKAGELIST.rstrip,
          libsample0 deb libs optional arch=any
          sample-ddeb deb libs optional arch=any
          sample-dev deb libdevel optional arch=any
          sample-udeb udeb libs optional arch=any
          PACKAGELIST
          'Checksums-Sha1' => "\n4a9cb2a7c77a68dc0fe54ba8ecef133a7c949e9d 964 sample_1.2.3~alpha2.tar.xz",
          'Checksums-Sha256' =>
            "\nc9d05185ca158bb804977fa9d7b922e8a0f644a2da41f99d2787dd61b1e2e2c5 964 sample_1.2.3~alpha2.tar.xz",
          'Files' => "\nadc69e57cda38d9bb7c8d59cacfb6869 964 sample_1.2.3~alpha2.tar.xz"
        }
      end
    end

    trait(:deb) do
      file_type { 'deb' }
      component { 'main' }
      architecture { 'amd64' }
      fields do
        {
          'Package' => 'libsample0',
          'Source' => package_file.package.name,
          'Version' => package_file.package.version,
          'Architecture' => 'amd64',
          'Maintainer' => "#{FFaker::NameCN.name} #{FFaker::Name.name} <#{FFaker::Internet.email}>",
          'Installed-Size' => '7',
          'Section' => 'libs',
          'Priority' => 'optional',
          'Multi-Arch' => 'same',
          'Homepage' => FFaker::Internet.http_url,
          'Description' => <<~DESCRIPTION.rstrip
          Some mostly empty lib
          Used in GitLab tests.

          Testing another paragraph.
          DESCRIPTION
        }
      end
    end

    trait(:deb_dev) do
      file_type { 'deb' }
      component { 'main' }
      architecture { 'amd64' }
      fields do
        {
          'Package' => 'sample-dev',
          'Source' => "#{package_file.package.name} (#{package_file.package.version})",
          'Version' => '1.2.3~binary',
          'Architecture' => 'amd64',
          'Maintainer' => "#{FFaker::Name.name} <#{FFaker::Internet.email}>",
          'Installed-Size' => '7',
          'Depends' => 'libsample0 (= 1.2.3~binary)',
          'Section' => 'libdevel',
          'Priority' => 'optional',
          'Multi-Arch' => 'same',
          'Homepage' => FFaker::Internet.http_url,
          'Description' => <<~DESCRIPTION.rstrip
          Some mostly empty development files
          Used in GitLab tests.

          Testing another paragraph.
          DESCRIPTION
        }
      end
    end

    trait(:udeb) do
      file_type { 'udeb' }
      component { 'main' }
      architecture { 'amd64' }
      fields { { 'a' => 'b' } }
    end

    trait(:ddeb) do
      file_type { 'ddeb' }
      component { 'main' }
      architecture { 'amd64' }
      fields { { 'a' => 'b' } }
    end

    trait(:buildinfo) do
      file_type { 'buildinfo' }
      component { 'main' }
      architecture { nil }
      fields { { 'Architecture' => 'amd64 source' } }
    end

    trait(:changes) do
      file_type { 'changes' }
      component { nil }
      architecture { nil }
      fields { { 'Architecture' => 'source amd64' } }
    end
  end
end
