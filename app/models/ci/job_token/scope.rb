# frozen_string_literal: true

# This model represents the surface where a CI_JOB_TOKEN can be used.
# A Scope is initialized with the project that the job token belongs to,
# and indicates what are all the other projects that the token could access.
#
# By default a job token can only access its own project, which is the same
# project that defines the scope.
# By adding ScopeLinks to the scope we can allow other projects to be accessed
# by the job token. This works as an allowlist of projects for a job token.
#
# If a project is not included in the scope we should not allow the job user
# to access it since operations using CI_JOB_TOKEN should be considered untrusted.

module Ci
  module JobToken
    class Scope
      attr_reader :source_project

      def initialize(project)
        @source_project = project
      end

      def includes?(target_project)
        # if the setting is disabled any project is considered to be in scope.
        return true unless source_project.ci_job_token_scope_enabled?

        target_project.id == source_project.id ||
          Ci::JobToken::ProjectScopeLink.from_project(source_project).to_project(target_project).exists?
      end

      def all_projects
        Project.from_union([
          Project.id_in(source_project),
          Project.where_exists(
            Ci::JobToken::ProjectScopeLink
              .from_project(source_project)
              .where('projects.id = ci_job_token_project_scope_links.target_project_id'))
        ], remove_duplicates: false)
      end
    end
  end
end
