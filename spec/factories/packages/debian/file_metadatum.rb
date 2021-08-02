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
      fields do
        {
          'Format' => '3.0 (native)',
          'Source' => package_file.package.name,
          'Binary' => 'sample-dev, libsample0, sample-udeb',
          'Architecture' => 'any',
          'Version': package_file.package.version,
          'Maintainer' => "#{FFaker::Name.name} <#{FFaker::Internet.email}>",
          'Homepage' => FFaker::Internet.http_url,
          'Standards-Version' => '4.5.0',
          'Build-Depends' => 'debhelper-compat (= 13)',
          'Package-List' => <<~EOF.rstrip,
           libsample0 deb libs optional arch=any',
           sample-dev deb libdevel optional arch=any',
           sample-udeb udeb libs optional arch=any',
          EOF
          'Checksums-Sha1' => "\nc5cfc111ea924842a89a06d5673f07dfd07de8ca 864 sample_1.2.3~alpha2.tar.xz",
          'Checksums-Sha256' => "\n40e4682bb24a73251ccd7c7798c0094a649091e5625d6a14bcec9b4e7174f3da 864 sample_1.2.3~alpha2.tar.xz",
          'Files' => "\nd5ca476e4229d135a88f9c729c7606c9 864 sample_1.2.3~alpha2.tar.xz"
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
        'Maintainer' => "#{FFaker::Name.name} <#{FFaker::Internet.email}>",
        'Installed-Size' => '7',
        'Section' => 'libs',
        'Priority' => 'optional',
        'Multi-Arch' => 'same',
        'Homepage' => FFaker::Internet.http_url,
        'Description' => <<~EOF.rstrip
        Some mostly empty lib
        Used in GitLab tests.

        Testing another paragraph.
        EOF
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
          'Description' => <<~EOF.rstrip
          Some mostly empty development files
          Used in GitLab tests.

          Testing another paragraph.
          EOF
        }
      end
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
