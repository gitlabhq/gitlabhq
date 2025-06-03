# frozen_string_literal: true

module Packages
  module Go
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      validates :version, format: { with: Gitlab::Regex.prefixed_semver_regex }
      validates :name, format: { with: Gitlab::Regex.package_name_regex }
    end
  end
end
