# frozen_string_literal: true

class Packages::Debian::GroupDistribution < ApplicationRecord
  def self.container_type
    :group
  end

  include Packages::Debian::Distribution

  def packages
    Packages::Package
      .for_projects(group.all_projects.public_only)
      .with_debian_codename(codename)
  end

  def package_files
    ::Packages::PackageFile.for_package_ids(packages.select(:id))
  end
end
