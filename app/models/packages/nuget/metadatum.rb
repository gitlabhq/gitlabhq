# frozen_string_literal: true

class Packages::Nuget::Metadatum < ApplicationRecord
  belongs_to :package, -> { where(package_type: :nuget) }, inverse_of: :nuget_metadatum

  validates :package, presence: true
  validates :license_url, public_url: { allow_blank: true }
  validates :project_url, public_url: { allow_blank: true }
  validates :icon_url, public_url: { allow_blank: true }

  validate :ensure_at_least_one_field_supplied
  validate :ensure_nuget_package_type

  private

  def ensure_at_least_one_field_supplied
    return if license_url? || project_url? || icon_url?

    errors.add(:base, _('Nuget metadatum must have at least license_url, project_url or icon_url set'))
  end

  def ensure_nuget_package_type
    return if package&.nuget?

    errors.add(:base, _('Package type must be NuGet'))
  end
end
