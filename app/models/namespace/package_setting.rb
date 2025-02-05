# frozen_string_literal: true

class Namespace::PackageSetting < ApplicationRecord
  include CascadingNamespaceSettingAttribute

  self.primary_key = :namespace_id
  self.table_name = 'namespace_package_settings'

  cascading_attr :maven_package_requests_forwarding
  cascading_attr :npm_package_requests_forwarding
  cascading_attr :pypi_package_requests_forwarding

  PackageSettingNotImplemented = Class.new(StandardError)

  PACKAGES_WITH_SETTINGS = %w[maven generic nuget terraform_module].freeze

  belongs_to :namespace, inverse_of: :package_setting_relation

  validates :namespace, presence: true
  validates :maven_duplicates_allowed, inclusion: { in: [true, false] }
  validates :maven_duplicate_exception_regex, untrusted_regexp: true, length: { maximum: 255 }
  validates :generic_duplicates_allowed, inclusion: { in: [true, false] }
  validates :generic_duplicate_exception_regex, untrusted_regexp: true, length: { maximum: 255 }
  validates :nuget_duplicates_allowed, inclusion: { in: [true, false] }
  validates :nuget_duplicate_exception_regex, untrusted_regexp: true, length: { maximum: 255 }
  validates :nuget_symbol_server_enabled, inclusion: { in: [true, false] }
  validates :terraform_module_duplicates_allowed, inclusion: { in: [true, false] }
  validates :terraform_module_duplicate_exception_regex, untrusted_regexp: true, length: { maximum: 255 }

  scope :namespace_id_in, ->(namespace_ids) { where(namespace_id: namespace_ids) }
  scope :with_terraform_module_duplicates_allowed_or_exception_regex, -> do
    where(terraform_module_duplicates_allowed: true)
      .or(where.not(terraform_module_duplicate_exception_regex: ''))
  end

  class << self
    def duplicates_allowed?(package)
      return true unless package
      raise PackageSettingNotImplemented unless PACKAGES_WITH_SETTINGS.include?(package.package_type)

      duplicates_allowed = package.package_settings["#{package.package_type}_duplicates_allowed"]

      regex = ::Gitlab::UntrustedRegexp.new(
        "\\A#{package.package_settings["#{package.package_type}_duplicate_exception_regex"]}\\z"
      )

      regex_match = regex.match?(package.name) || regex.match?(package.version)

      duplicates_allowed ? !regex_match : regex_match
    end
  end
end
