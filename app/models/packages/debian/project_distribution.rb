# frozen_string_literal: true

class Packages::Debian::ProjectDistribution < ApplicationRecord
  def self.container_type
    :project
  end

  include Packages::Debian::Distribution
end
