# frozen_string_literal: true

class Packages::Debian::GroupDistributionKey < ApplicationRecord
  def self.container_type
    :group
  end

  include Packages::Debian::DistributionKey
end
