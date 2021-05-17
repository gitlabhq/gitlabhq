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
        .including_build_info
        .including_project_route
        .including_tags
        .displayable
        .find(@package_id)
    end
  end
end
