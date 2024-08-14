# frozen_string_literal: true

module Packages
  module Helm
    class Package < ::Packages::Package
      self.allow_legacy_sti_class = true

      validates :name, format: { with: Gitlab::Regex.helm_package_regex }
      validates :version, format: { with: Gitlab::Regex.helm_version_regex }
    end
  end
end
