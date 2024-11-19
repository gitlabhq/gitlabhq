# frozen_string_literal: true

class Packages::Npm::Metadatum < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  MAX_PACKAGE_JSON_SIZE = 20_000
  MIN_PACKAGE_JSON_FIELD_SIZE_FOR_ERROR_TRACKING = 5_000
  NUM_FIELDS_FOR_ERROR_TRACKING = 5

  belongs_to :package, class_name: 'Packages::Npm::Package', inverse_of: :npm_metadatum

  # TODO: Remove with the rollout of the FF npm_extract_npm_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/501469
  belongs_to :legacy_package, -> {
    where(package_type: :npm)
  }, inverse_of: :npm_metadatum, class_name: 'Packages::Package', foreign_key: :package_id

  validates :package, presence: true, if: -> { npm_extract_npm_package_model_enabled? }

  # TODO: Remove with the rollout of the FF npm_extract_npm_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/501469
  validates :legacy_package, presence: true, unless: -> { npm_extract_npm_package_model_enabled? }
  # From https://github.com/npm/registry/blob/master/docs/responses/package-metadata.md#abbreviated-version-object
  validates :package_json, json_schema: { filename: "npm_package_json" }
  validate :ensure_npm_package_type, unless: -> { npm_extract_npm_package_model_enabled? }
  validate :ensure_package_json_size

  scope :package_id_in, ->(package_ids) { where(package_id: package_ids) }

  private

  def ensure_npm_package_type
    return if legacy_package&.npm?

    errors.add(:base, _('Package type must be NPM'))
  end

  def ensure_package_json_size
    return if package_json.to_s.size < MAX_PACKAGE_JSON_SIZE

    errors.add(:package_json, :too_large,
      message: format(
        _('structure is too large. Maximum size is %{max_size} characters'),
        max_size: MAX_PACKAGE_JSON_SIZE
      )
    )
  end

  def npm_extract_npm_package_model_enabled?
    Feature.enabled?(:npm_extract_npm_package_model, Feature.current_request)
  end
  strong_memoize_attr :npm_extract_npm_package_model_enabled?
end
