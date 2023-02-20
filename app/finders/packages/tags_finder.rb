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
    packages = project.packages
                      .with_name(package_name)
    packages = packages.with_package_type(package_type) if package_type.present?

    Packages::Tag.for_package_ids(packages.select(:id))
  end

  private

  def package_type
    params[:package_type]
  end
end
