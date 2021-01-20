# frozen_string_literal: true

class Packages::Debian::GroupDistribution < ApplicationRecord
  def self.container_type
    :group
  end

  include Packages::Debian::Distribution
end
