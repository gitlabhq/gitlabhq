# frozen_string_literal: true

class Namespace::PackageSetting < ApplicationRecord
  self.primary_key = :namespace_id
  self.table_name = 'namespace_package_settings'

  PackageSettingNotImplemented = Class.new(StandardError)

  PACKAGES_WITH_SETTINGS = %w[maven generic].freeze

  belongs_to :namespace, inverse_of: :package_setting_relation

  validates :namespace, presence: true
  validates :maven_duplicates_allowed, inclusion: { in: [true, false] }
  validates :maven_duplicate_exception_regex, untrusted_regexp: true, length: { maximum: 255 }
  validates :generic_duplicates_allowed, inclusion: { in: [true, false] }
  validates :generic_duplicate_exception_regex, untrusted_regexp: true, length: { maximum: 255 }

  class << self
    def duplicates_allowed?(package)
      return true unless package
      raise PackageSettingNotImplemented unless PACKAGES_WITH_SETTINGS.include?(package.package_type)

      duplicates_allowed = package.package_settings["#{package.package_type}_duplicates_allowed"]
      regex = ::Gitlab::UntrustedRegexp.new("\\A#{package.package_settings["#{package.package_type}_duplicate_exception_regex"]}\\z")

      duplicates_allowed || regex.match?(package.name) || regex.match?(package.version)
    end
  end
end
