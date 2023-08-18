# frozen_string_literal: true

class Packages::Nuget::Metadatum < ApplicationRecord
  include Packages::Nuget::VersionNormalizable

  MAX_AUTHORS_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 4000
  MAX_URL_LENGTH = 255

  belongs_to :package, -> { where(package_type: :nuget) }, inverse_of: :nuget_metadatum

  validates :package, presence: true
  validates :license_url, public_url: { allow_blank: true }, length: { maximum: MAX_URL_LENGTH }
  validates :project_url, public_url: { allow_blank: true }, length: { maximum: MAX_URL_LENGTH }
  validates :icon_url, public_url: { allow_blank: true }, length: { maximum: MAX_URL_LENGTH }
  validates :authors, presence: true, length: { maximum: MAX_AUTHORS_LENGTH }
  validates :description, presence: true, length: { maximum: MAX_DESCRIPTION_LENGTH }
  validates :normalized_version, presence: true

  validate :ensure_nuget_package_type

  delegate :version, to: :package, prefix: true

  scope :normalized_version_in, ->(version) { where(normalized_version: version.downcase) }

  private

  def ensure_nuget_package_type
    return if package&.nuget?

    errors.add(:base, _('Package type must be NuGet'))
  end
end
