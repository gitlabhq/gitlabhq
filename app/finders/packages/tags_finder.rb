# frozen_string_literal: true

class Packages::TagsFinder
  delegate :find_by_name, to: :execute

  def initialize(project, package_name, packages_class)
    @project = project
    @package_name = package_name
    @packages_class = packages_class
  end

  def execute
    Packages::Tag.for_package_ids(packages.select(:id))
  end

  private

  attr_reader :project, :package_name, :packages_class

  def packages
    packages_class.for_projects(project).with_name(package_name)
  end
end
