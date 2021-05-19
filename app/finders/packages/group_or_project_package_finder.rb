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
        packages_for_project(@project_or_group)
      elsif group?
        packages_visible_to_user(@current_user, within_group: @project_or_group)
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
  end
end
