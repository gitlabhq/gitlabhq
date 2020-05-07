# frozen_string_literal: true

module ReleasesHelper
  IMAGE_PATH = 'illustrations/releases.svg'
  DOCUMENTATION_PATH = 'user/project/releases/index'

  def illustration
    image_path(IMAGE_PATH)
  end

  def help_page(anchor: nil)
    help_page_path(DOCUMENTATION_PATH, anchor: anchor)
  end

  def data_for_releases_page
    {
      project_id: @project.id,
      illustration_path: illustration,
      documentation_path: help_page
    }.tap do |data|
      data[:new_release_path] = new_project_tag_path(@project) if can?(current_user, :create_release, @project)
    end
  end

  def data_for_edit_release_page
    {
      project_id: @project.id,
      tag_name: @release.tag,
      markdown_preview_path: preview_markdown_path(@project),
      markdown_docs_path: help_page_path('user/markdown'),
      releases_page_path: project_releases_path(@project, anchor: @release.tag),
      update_release_api_docs_path: help_page_path('api/releases/index.md', anchor: 'update-a-release'),
      release_assets_docs_path: help_page(anchor: 'release-assets'),
      manage_milestones_path: project_milestones_path(@project),
      new_milestone_path: new_project_milestone_url(@project)
    }
  end
end
