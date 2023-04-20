# frozen_string_literal: true

class Packages::Npm::Metadatum < ApplicationRecord
  belongs_to :package, -> { where(package_type: :npm) }, inverse_of: :npm_metadatum

  validates :package, presence: true
  # From https://github.com/npm/registry/blob/master/docs/responses/package-metadata.md#abbreviated-version-object
  validates :package_json, json_schema: { filename: "npm_package_json" }
  validate :ensure_npm_package_type
  validate :ensure_package_json_size

  scope :package_id_in, ->(package_ids) { where(package_id: package_ids) }

  private

  def ensure_npm_package_type
    return if package&.npm?

    errors.add(:base, _('Package type must be NPM'))
  end

  def ensure_package_json_size
    return if package_json.to_s.size < 20000

    errors.add(:package_json, _('structure is too large'))
  end
end
