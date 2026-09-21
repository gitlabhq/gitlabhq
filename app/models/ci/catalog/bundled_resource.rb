# frozen_string_literal: true

module Ci
  module Catalog
    class BundledResource < ::ApplicationRecord
      self.table_name = 'catalog_bundled_resources'

      has_many :versions, class_name: 'Ci::Catalog::BundledResources::Version',
        foreign_key: :catalog_bundled_resource_id, inverse_of: :bundled_resource
      has_many :components, class_name: 'Ci::Catalog::BundledResources::Component',
        foreign_key: :catalog_bundled_resource_id, inverse_of: :bundled_resource

      normalizes :server_fqdn, with: ->(value) { value.downcase }
      normalizes :full_path, with: ->(value) { value.downcase }

      validates :server_fqdn, presence: true, length: { maximum: 255 }
      validates :name, presence: true, length: { maximum: 255 }
      validates :full_path, presence: true, length: { maximum: 1024 },
        uniqueness: { scope: :server_fqdn }
      validates :description, length: { maximum: 1024 }

      scope :ordered_by_id, -> { order(id: :asc) }

      scope :by_natural_key, ->(server_fqdn, full_path) {
        where(server_fqdn: server_fqdn, full_path: full_path)
      }

      def self.find_bundled_version(server_fqdn:, full_path:, semver:)
        parsed = ::Packages::SemVer.parse(semver.to_s, prefixed: semver.to_s.start_with?('v'))
        return unless parsed

        by_natural_key(server_fqdn, full_path).first&.versions&.find_by(
          semver_major: parsed.major,
          semver_minor: parsed.minor,
          semver_patch: parsed.patch,
          semver_prerelease: parsed.prerelease.presence
        )
      end

      def self.find_bundled_component(server_fqdn:, full_path:, semver:, name:)
        find_bundled_version(server_fqdn: server_fqdn, full_path: full_path, semver: semver)
          &.components&.find_by(name: name)
      end

      def latest_version
        versions.order_by_semantic_version_desc.first
      end

      def latest_version_name
        latest_version&.semver&.to_s
      end
    end
  end
end
