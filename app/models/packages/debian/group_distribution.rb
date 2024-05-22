# frozen_string_literal: true

class Packages::Debian::GroupDistribution < ApplicationRecord
  def self.container_type
    :group
  end

  include Packages::Debian::Distribution

  def packages
    ::Packages::Debian::Package
      .for_projects(group.all_projects.public_only)
      .with_codename(codename)
  end
end
