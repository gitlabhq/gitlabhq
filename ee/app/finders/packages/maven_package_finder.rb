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

  def packages
    project.packages.joins(:maven_metadatum)
      .where(packages_maven_metadata: { path: path })
  end
end
