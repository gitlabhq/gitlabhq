# frozen_string_literal: true

class Packages::Pypi::Metadatum < ApplicationRecord
  self.primary_key = :package_id

  belongs_to :package, -> { where(package_type: :pypi) }, inverse_of: :pypi_metadatum

  validates :package, presence: true

  validate :pypi_package_type

  private

  def pypi_package_type
    unless package&.pypi?
      errors.add(:base, _('Package type must be PyPi'))
    end
  end
end
