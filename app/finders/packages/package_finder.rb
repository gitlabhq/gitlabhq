# frozen_string_literal: true
module Packages
  class PackageFinder
    def initialize(project, package_id)
      @project = project
      @package_id = package_id
    end

    def execute
      @project
        .packages
        .processed
        .find(@package_id)
    end
  end
end
