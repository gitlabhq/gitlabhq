# frozen_string_literal: true

class Packages::Debian::Publication < ApplicationRecord
  belongs_to :package,
    -> { where.not(version: nil) },
    inverse_of: :publication,
    class_name: 'Packages::Debian::Package'
  belongs_to :distribution,
    inverse_of: :publications,
    class_name: 'Packages::Debian::ProjectDistribution',
    foreign_key: :distribution_id

  validates :package, presence: true

  validates :distribution, presence: true
end
