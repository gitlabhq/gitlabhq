# frozen_string_literal: true

module Routing
  module ProjectsHelper
    def project_tree_path(project, ref = nil, *args)
      namespace_project_tree_path(project.namespace, project, ref || @ref || project.repository.root_ref, *args) # rubocop:disable Cop/ProjectPathHelper
    end

    def project_commits_path(project, ref = nil, *args)
      namespace_project_commits_path(project.namespace, project, ref || @ref || project.repository.root_ref, *args) # rubocop:disable Cop/ProjectPathHelper
    end

    def project_ref_path(project, ref_name, *args)
      project_commits_path(project, ref_name, *args)
    end

    def environment_path(environment, *args)
      project_environment_path(environment.project, environment, *args)
    end

    def environment_metrics_path(environment, *args)
      metrics_project_environment_path(environment.project, environment, *args)
    end

    def environment_delete_path(environment, *args)
      expose_path(api_v4_projects_environments_path(id: environment.project.id, environment_id: environment.id))
    end

    def issue_path(entity, *args)
      project_issue_path(entity.project, entity, *args)
    end

    def merge_request_path(entity, *args)
      project_merge_request_path(entity.project, entity, *args)
    end

    def pipeline_path(pipeline, *args)
      project_pipeline_path(pipeline.project, pipeline.id, *args)
    end

    def issue_url(entity, *args)
      project_issue_url(entity.project, entity, *args)
    end

    def merge_request_url(entity, *args)
      project_merge_request_url(entity.project, entity, *args)
    end

    def pipeline_url(pipeline, *args)
      project_pipeline_url(pipeline.project, pipeline.id, *args)
    end

    def pipeline_job_url(pipeline, build, *args)
      project_job_url(pipeline.project, build.id, *args)
    end

    def commits_url(entity, *args)
      project_commits_url(entity.project, entity.source_ref, *args)
    end

    def commit_url(entity, *args)
      project_commit_url(entity.project, entity.sha, *args)
    end

    def release_url(entity, *args)
      project_release_url(entity.project, entity, *args)
    end

    def edit_milestone_path(entity, *args)
      if entity.resource_parent.is_a?(Group)
        edit_group_milestone_path(entity.resource_parent, entity, *args)
      else
        edit_project_milestone_path(entity.resource_parent, entity, *args)
      end
    end

    def toggle_subscription_path(entity, *args)
      if entity.is_a?(Issue)
        toggle_subscription_project_issue_path(entity.project, entity)
      else
        toggle_subscription_project_merge_request_path(entity.project, entity)
      end
    end
  end
end
