# frozen_string_literal: true

module Packages
  module Rubygems
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      has_one :rubygems_metadatum, inverse_of: :package, class_name: 'Packages::Rubygems::Metadatum'

      validates :name, format: { with: Gitlab::Regex.package_name_regex }
    end
  end
end
