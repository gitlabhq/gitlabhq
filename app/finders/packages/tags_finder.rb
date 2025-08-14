# frozen_string_literal: true

class Packages::TagsFinder
  attr_reader :project, :package_name, :params

  delegate :find_by_name, to: :execute

  def initialize(project, package_name, params = {})
    @project = project
    @package_name = package_name
    @params = params
  end

  def execute
    Packages::Tag.for_package_ids(packages.select(:id))
  end

  private

  def package_type
    params[:package_type]
  end

  def packages_class
    params.fetch(:packages_class, ::Packages::Package)
  end

  def packages
    if Feature.enabled?(:packages_tags_finder_use_packages_class, project)
      packages_class.for_projects(project).with_name(package_name)
    else
      packages = project.packages.with_name(package_name)
      return packages unless package_type.present?

      packages.with_package_type(package_type)
    end
  end
end
