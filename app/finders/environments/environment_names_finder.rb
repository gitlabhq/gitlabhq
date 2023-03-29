# frozen_string_literal: true

module Environments
  # Finder for obtaining the unique environment names of a project or group.
  #
  # This finder exists so that the merge requests "environments" filter can be
  # populated with a unique list of environment names. If we retrieve _just_ the
  # environments, duplicates may be present (e.g. multiple projects in a group
  # having a "staging" environment).
  #
  # In addition, this finder only produces unfoldered environments. We do this
  # because when searching for environments we want to exclude review app
  # environments.
  class EnvironmentNamesFinder
    attr_reader :project_or_group, :current_user

    def initialize(project_or_group, current_user = nil)
      @project_or_group = project_or_group
      @current_user = current_user
    end

    def execute
      all_environments.unfoldered.order_by_name.pluck_unique_names
    end

    def all_environments
      if project_or_group.is_a?(Namespace)
        namespace_environments
      else
        project_environments
      end
    end

    def namespace_environments
      projects = project_or_group
        .all_projects
        .filter_by_feature_visibility(:environments, current_user)

      Environment.for_project(projects)
    end

    def project_environments
      if Ability.allowed?(current_user, :read_environment, project_or_group)
        project_or_group.environments
      else
        Environment.none
      end
    end
  end
end
