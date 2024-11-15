# frozen_string_literal: true

class Packages::Nuget::Metadatum < ApplicationRecord
  include Packages::Nuget::VersionNormalizable

  MAX_AUTHORS_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 4000
  MAX_URL_LENGTH = 255

  belongs_to :package, class_name: 'Packages::Nuget::Package', inverse_of: :nuget_metadatum

  validates :package, presence: true
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

  delegate :version, to: :package, prefix: true

  scope :normalized_version_in, ->(version) { where(normalized_version: version.downcase) }

  private

  def url_validation_enabled?
    !Gitlab::CurrentSettings.current_application_settings.nuget_skip_metadata_url_validation
  end

  def ensure_valid_urls
    %w[license_url project_url icon_url].each do |field|
      value = attributes[field]

      next if value.blank?

      errors.add(field, _('is an invalid URL')) unless Gitlab::UrlSanitizer.valid_web?(value)
    end
  end
end
