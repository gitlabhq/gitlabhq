# frozen_string_literal: true
class Packages::PackageFileFinder
  attr_reader :package, :file_name

  def initialize(package, file_name)
    @package = package
    @file_name = file_name
  end

  def execute
    package_files.last
  end

  def execute!
    package_files.last!
  end

  private

  def package_files
    package.package_files.where(file_name: file_name)
  end
end
