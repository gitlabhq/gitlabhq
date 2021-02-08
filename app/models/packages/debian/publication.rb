# frozen_string_literal: true

class Packages::Debian::Publication < ApplicationRecord
  belongs_to :package,
    -> { where(package_type: :debian).where.not(version: nil) },
    inverse_of: :debian_publication,
    class_name: 'Packages::Package'
  belongs_to :distribution,
    inverse_of: :publications,
    class_name: 'Packages::Debian::ProjectDistribution',
    foreign_key: :distribution_id

  validates :package, presence: true
  validate :valid_debian_package_type

  validates :distribution, presence: true

  private

  def valid_debian_package_type
    return errors.add(:package, _('type must be Debian')) unless package&.debian?
    return errors.add(:package, _('must be a Debian package')) unless package.debian_package?
  end
end
