# frozen_string_literal: true

class Packages::Debian::ProjectDistribution < ApplicationRecord
  def self.container_type
    :project
  end

  has_many :publications, class_name: 'Packages::Debian::Publication', inverse_of: :distribution, foreign_key: :distribution_id
  has_many :packages, class_name: 'Packages::Package', through: :publications

  include Packages::Debian::Distribution
end
