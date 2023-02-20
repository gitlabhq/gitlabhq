# frozen_string_literal: true

class Packages::Debian::GroupDistribution < ApplicationRecord
  def self.container_type
    :group
  end

  include Packages::Debian::Distribution

  def packages
    Packages::Package
      .for_projects(group.all_projects.public_only)
      .debian
      .with_debian_codename(codename)
  end
end
