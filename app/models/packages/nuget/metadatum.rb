# frozen_string_literal: true

class Packages::Nuget::Metadatum < ApplicationRecord
  MAX_AUTHORS_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 4000

  belongs_to :package, -> { where(package_type: :nuget) }, inverse_of: :nuget_metadatum

  validates :package, presence: true
  validates :license_url, public_url: { allow_blank: true }
  validates :project_url, public_url: { allow_blank: true }
  validates :icon_url, public_url: { allow_blank: true }
  validates :authors, presence: true, length: { maximum: MAX_AUTHORS_LENGTH }
  validates :description, presence: true, length: { maximum: MAX_DESCRIPTION_LENGTH }

  validate :ensure_nuget_package_type

  private

  def ensure_nuget_package_type
    return if package&.nuget?

    errors.add(:base, _('Package type must be NuGet'))
  end
end
