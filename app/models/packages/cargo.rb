# frozen_string_literal: true

module Packages
  module Cargo
    # Dots are not valid in a cargo package name, so the shared
    # 'Temporary.Package' default cannot be used here.
    TEMPORARY_PACKAGE_NAME = 'Cargo-Temporary-Package'

    def self.table_name_prefix
      'packages_cargo_'
    end

    def self.normalize_name(package_name)
      package_name.downcase.tr('_', '-')
    end

    def self.normalize_version(package_version)
      package_version.sub(/\+.*\z/, '')
    end
  end
end
