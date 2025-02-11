# frozen_string_literal: true

module ReleasesHelper
  IMAGE_PATH = 'illustrations/rocket-launch-md.svg'
  DOCUMENTATION_PATH = 'user/project/releases/_index'

  # This needs to be kept in sync with the constant in
  # app/assets/javascripts/releases/constants.js
  DEFAULT_SORT = 'RELEASED_AT_DESC'

  def illustration
    image_path(IMAGE_PATH)
  end

  def releases_help_page_path(anchor: nil)
    help_page_path(DOCUMENTATION_PATH, anchor: anchor)
  end

  def data_for_releases_page
    {
      project_id: @project.id,
      project_path: @project.full_path,
      illustration_path: illustration,
      documentation_path: releases_help_page_path,
      atom_feed_path: project_releases_path(@project, rss_url_options)
    }.tap do |data|
      if can?(current_user, :create_release, @project)
        data[:new_release_path] = new_project_release_path(@project)
      end
    end
  end

  # For simplicity, only optimize non-paginated requests
  def use_startup_query_for_index_page?
    params[:before].nil? && params[:after].nil?
  end

  def index_page_startup_query_variables
    {
      fullPath: @project.full_path,
      sort: DEFAULT_SORT,
      first: 1
    }
  end

  def data_for_show_page
    {
      project_id: @project.id,
      project_path: @project.full_path,
      tag_name: @release.tag,
      deployments: deployments_for_release.to_json
    }
  end

  def data_for_edit_release_page
    new_edit_pages_shared_data.merge(
      tag_name: @release.tag,
      releases_page_path: project_releases_path(@project, anchor: @release.tag),
      delete_release_docs_path: releases_help_page_path(anchor: 'delete-a-release')
    )
  end

  def data_for_new_release_page
    new_edit_pages_shared_data.merge(
      tag_name: params[:tag_name],
      default_branch: @project.default_branch,
      releases_page_path: project_releases_path(@project)
    )
  end

  def group_milestone_project_releases_available?(project)
    false
  end

  private

  def new_edit_pages_shared_data
    {
      project_id: @project.id,
      group_id: @project.group&.id,
      group_milestones_available: group_milestone_project_releases_available?(@project),
      project_path: @project.full_path,
      markdown_preview_path: preview_markdown_path(@project),
      markdown_docs_path: help_page_path('user/markdown.md'),
      release_assets_docs_path: releases_help_page_path(anchor: 'release-assets'),
      manage_milestones_path: project_milestones_path(@project),
      new_milestone_path: new_project_milestone_path(@project, redirect_path: 'new_release'),
      edit_release_docs_path: releases_help_page_path(anchor: 'edit-a-release'),
      upcoming_release_docs_path: releases_help_page_path(anchor: 'upcoming-releases')
    }
  end

  def deployments_for_release
    return [] unless can?(current_user, :read_deployment, @project)

    project = @release.project
    deployments = @release.related_deployments
    commit = project.repository.commit(@release.tag)

    deployments.map do |deployment|
      user = deployment.deployable&.user
      environment = deployment.environment

      {
        environment: {
          name: environment&.name,
          url: environment ? project_environment_url(project, environment) : nil
        },
        status: deployment.status,
        deployment: {
          id: deployment.id,
          url: project_environment_deployment_path(project, environment, deployment)
        },
        commit: {
          sha: commit.id,
          name: commit.author_name,
          commit_url: project_commit_url(project, commit),
          short_sha: commit.short_id,
          title: commit.title
        },

        triggerer: if user
                     {
                       name: user.name,
                       web_url: user_url(user),
                       avatar_url: user.avatar_url
                     }
                   end,

        created_at: deployment.created_at,
        finished_at: deployment.finished_at
      }
    end
  end
end

ReleasesHelper.prepend_mod_with('ReleasesHelper')
