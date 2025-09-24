# frozen_string_literal: true

module Packages
  module Cargo
    class Metadatum < ApplicationRecord
      self.primary_key = :package_id

      belongs_to :package, class_name: 'Packages::Cargo::Package', inverse_of: :cargo_metadatum
      belongs_to :project

      validates :package, presence: true
      validates :index_content,
        json_schema: { filename: 'cargo_package_index_content', detail_errors: true, size_limit: 64.kilobytes }

      validates :normalized_name,
        presence: true,
        length: { maximum: 64 },
        format: { with: Gitlab::Regex.cargo_package_normalized_name_regex,
                  message: 'must contain only lowercase letters, numbers, and hyphens' }

      validates :normalized_version,
        presence: true,
        length: { maximum: 255 },
        format: { with: Gitlab::Regex.semver_regex, message: 'must be a valid semantic version' }

      validates :project_id, uniqueness: {
        scope: [:normalized_name, :normalized_version],
        message: 'already has a package with this normalized name and version'
      }

      before_validation :set_normalized_values, unless: -> { normalized_name? && normalized_version? }

      private

      def set_normalized_values
        self.normalized_name = Packages::Cargo.normalize_name(package.name) if package&.name
        self.normalized_version = Packages::Cargo.normalize_version(package.version) if package&.version
      end
    end
  end
end
