# frozen_string_literal: true

class Packages::Debian::ProjectDistributionKey < ApplicationRecord
  def self.container_type
    :project
  end

  include Packages::Debian::DistributionKey
end
