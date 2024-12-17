# frozen_string_literal: true

class Packages::Npm::Metadatum < ApplicationRecord
  MAX_PACKAGE_JSON_SIZE = 20_000
  MIN_PACKAGE_JSON_FIELD_SIZE_FOR_ERROR_TRACKING = 5_000
  NUM_FIELDS_FOR_ERROR_TRACKING = 5

  belongs_to :package, class_name: 'Packages::Npm::Package', inverse_of: :npm_metadatum

  validates :package, presence: true

  # From https://github.com/npm/registry/blob/master/docs/responses/package-metadata.md#abbreviated-version-object
  validates :package_json, json_schema: { filename: "npm_package_json" }
  validate :ensure_package_json_size

  scope :package_id_in, ->(package_ids) { where(package_id: package_ids) }

  private

  def ensure_package_json_size
    return if package_json.to_s.size < MAX_PACKAGE_JSON_SIZE

    errors.add(:package_json, :too_large,
      message: format(
        _('structure is too large. Maximum size is %{max_size} characters'),
        max_size: MAX_PACKAGE_JSON_SIZE
      )
    )
  end
end
