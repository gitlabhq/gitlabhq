# frozen_string_literal: true

module Packages
  class GroupOrProjectPackageFinder
    include ::Packages::FinderHelper

    def initialize(current_user, project_or_group, params = {})
      @current_user = current_user
      @project_or_group = project_or_group
      @params = params
    end

    def execute
      raise NotImplementedError
    end

    def execute!
      raise NotImplementedError
    end

    private

    def packages
      raise NotImplementedError
    end

    def base
      if project?
        project_packages
      elsif group?
        group_packages
      else
        ::Packages::Package.none
      end
    end

    def project?
      @project_or_group.is_a?(::Project)
    end

    def group?
      @project_or_group.is_a?(::Group)
    end

    def project_packages
      packages_for_project(@project_or_group)
    end

    def group_packages
      packages_visible_to_user(@current_user, within_group: @project_or_group)
    end
  end
end
