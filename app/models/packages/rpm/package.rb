# frozen_string_literal: true

module Packages
  module Rpm
    class Package < ::Packages::Package
      self.allow_legacy_sti_class = true

      has_one :rpm_metadatum, inverse_of: :package, class_name: 'Packages::Rpm::Metadatum'

      validates :name, format: { with: Gitlab::Regex.package_name_regex }
    end
  end
end
