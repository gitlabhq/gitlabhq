# frozen_string_literal: true
class Packages::MavenPackageFinder
  attr_reader :project, :path

  def initialize(project, path)
    @project = project
    @path = path
  end

  def execute
    packages.last
  end

  def execute!
    packages.last!
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def packages
    project.packages.joins(:maven_metadatum)
      .where(packages_maven_metadata: { path: path })
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
