# frozen_string_literal: true

module Packages
  module TerraformModule
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      has_one :terraform_module_metadatum, inverse_of: :package, class_name: 'Packages::TerraformModule::Metadatum'

      accepts_nested_attributes_for :terraform_module_metadatum

      validates :name, format: { with: Gitlab::Regex.terraform_module_package_name_regex }
      validates :version, format: { with: Gitlab::Regex.semver_regex, message: Gitlab::Regex.semver_regex_message }

      scope :unscope_order, -> { unscope(:order) }
      scope :order_metadatum_semver_desc, -> {
        joins(:terraform_module_metadatum).merge(::Packages::TerraformModule::Metadatum.order_by_semantic_version_desc)
      }
    end
  end
end
