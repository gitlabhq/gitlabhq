# frozen_string_literal: true

class Packages::Nuget::Metadatum < ApplicationRecord
  include Packages::Nuget::VersionNormalizable
  include Gitlab::Utils::StrongMemoize

  MAX_AUTHORS_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 4000
  MAX_URL_LENGTH = 255

  belongs_to :package, class_name: 'Packages::Nuget::Package', inverse_of: :nuget_metadatum

  # TODO: Remove with the rollout of the FF nuget_extract_nuget_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/499602
  belongs_to :legacy_package, -> {
    where(package_type: :nuget)
  }, inverse_of: :nuget_metadatum, class_name: 'Packages::Package', foreign_key: :package_id

  validates :package, presence: true, if: -> { nuget_extract_nuget_package_model_enabled? }

  # TODO: Remove with the rollout of the FF nuget_extract_nuget_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/499602
  validates :legacy_package, presence: true, unless: -> { nuget_extract_nuget_package_model_enabled? }

  validate :ensure_valid_urls
  with_options if: :url_validation_enabled?, public_url: { allow_blank: true } do
    validates :license_url
    validates :project_url
    validates :icon_url
  end
  with_options length: { maximum: MAX_URL_LENGTH } do
    validates :license_url
    validates :project_url
    validates :icon_url
  end
  validates :authors, presence: true, length: { maximum: MAX_AUTHORS_LENGTH }
  validates :description, presence: true, length: { maximum: MAX_DESCRIPTION_LENGTH }
  validates :normalized_version, presence: true

  validate :ensure_nuget_package_type, unless: -> { nuget_extract_nuget_package_model_enabled? }

  # TODO: Use `prefix: true` with the rollout of the FF nuget_extract_nuget_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/499602
  delegate :version, to: :package_or_legacy_package, prefix: :package

  scope :normalized_version_in, ->(version) { where(normalized_version: version.downcase) }

  private

  def url_validation_enabled?
    !Gitlab::CurrentSettings.current_application_settings.nuget_skip_metadata_url_validation
  end

  def ensure_nuget_package_type
    return if legacy_package&.nuget?

    errors.add(:base, _('Package type must be NuGet'))
  end

  def ensure_valid_urls
    %w[license_url project_url icon_url].each do |field|
      value = attributes[field]

      next if value.blank?

      errors.add(field, _('is an invalid URL')) unless Gitlab::UrlSanitizer.valid_web?(value)
    end
  end

  # TODO: Use `package` directly in `delegate` with the rollout of
  # the FF nuget_extract_nuget_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/499602
  def package_or_legacy_package
    if nuget_extract_nuget_package_model_enabled?
      package
    else
      legacy_package
    end
  end

  def nuget_extract_nuget_package_model_enabled?
    Feature.enabled?(:nuget_extract_nuget_package_model, Feature.current_request)
  end
  strong_memoize_attr :nuget_extract_nuget_package_model_enabled?
end
