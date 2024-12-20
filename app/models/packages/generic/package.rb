# frozen_string_literal: true

module Packages
  module Generic
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      validates :name, format: { with: Gitlab::Regex.generic_package_name_regex }
      validates :version, presence: true, format: { with: Gitlab::Regex.generic_package_version_regex }
    end
  end
end
