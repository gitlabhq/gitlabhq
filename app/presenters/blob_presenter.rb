# frozen_string_literal: true
require 'ipynbdiff'

class BlobPresenter < Gitlab::View::Presenter::Delegated
  include ApplicationHelper
  include BlobHelper
  include DiffHelper
  include TreeHelper
  include ChecksCollaboration

  presents ::Blob, as: :blob

  def highlight(to: nil, plain: nil)
    load_all_blob_data

    Gitlab::Highlight.highlight(
      blob.path,
      blob_data(to),
      language: blob_language,
      plain: plain
    )
  end

  def plain_data
    return if blob.binary?

    highlight(plain: false)
  end

  def blob_data(to)
    @_blob_data ||= Gitlab::Diff::CustomDiff.transformed_blob_data(blob) || limited_blob_data(to: to)
  end

  def blob_language
    @_blob_language ||= Gitlab::Diff::CustomDiff.transformed_blob_language(blob) || language
  end

  def raw_plain_data
    blob.data unless blob.binary?
  end

  def web_url
    url_helpers.project_blob_url(project, ref_qualified_path)
  end

  def web_path
    url_helpers.project_blob_path(project, ref_qualified_path)
  end

  def edit_blob_path
    url_helpers.project_edit_blob_path(project, ref_qualified_path)
  end

  def raw_path
    url_helpers.project_raw_path(project, ref_qualified_path)
  end

  def replace_path
    url_helpers.project_create_blob_path(project, ref_qualified_path)
  end

  def pipeline_editor_path
    project_ci_pipeline_editor_path(project, branch_name: blob.commit_id) if can_collaborate_with_project?(project) && blob.path == project.ci_config_path_or_default
  end

  def find_file_path
    url_helpers.project_find_file_path(project, ref_qualified_path)
  end

  def blame_path
    url_helpers.project_blame_path(project, ref_qualified_path)
  end

  def history_path
    url_helpers.project_commits_path(project, ref_qualified_path)
  end

  def permalink_path
    url_helpers.project_blob_path(project, File.join(project.repository.commit.sha, blob.path))
  end

  def environment_formatted_external_url
    return unless environment

    environment.formatted_external_url
  end

  def environment_external_url_for_route_map
    return unless environment

    environment.external_url_for(blob.path, blob.commit_id)
  end

  # Will be overridden in EE
  def code_owners
    []
  end

  def fork_and_edit_path
    fork_path_for_current_user(project, edit_blob_path)
  end

  def ide_fork_and_edit_path
    fork_path_for_current_user(project, ide_edit_path)
  end

  def can_modify_blob?
    super(blob, project, blob.commit_id)
  end

  def can_current_user_push_to_branch?
    return false unless current_user && project.repository.branch_exists?(blob.commit_id)

    user_access(project).can_push_to_branch?(blob.commit_id)
  end

  def archived?
    project.archived
  end

  def ide_edit_path
    super(project, blob.commit_id, blob.path)
  end

  def external_storage_url
    return unless static_objects_external_storage_enabled?

    external_storage_url_or_path(url_helpers.project_raw_url(project, ref_qualified_path), project)
  end

  private

  def url_helpers
    Gitlab::Routing.url_helpers
  end

  def environment
    environment_params = project.repository.branch_exists?(blob.commit_id) ? { ref: blob.commit_id } : { sha: blob.commit_id }
    environment_params[:find_latest] = true
    ::Environments::EnvironmentsByDeploymentsFinder.new(project, current_user, environment_params).execute.last
  end

  def project
    blob.repository.project
  end

  def ref_qualified_path
    File.join(blob.commit_id, blob.path)
  end

  def load_all_blob_data
    blob.load_all_data! if blob.respond_to?(:load_all_data!)
  end

  def limited_blob_data(to: nil)
    return blob.data if to.blank?

    # Even though we don't need all the lines at the start of the file (e.g
    # viewing the middle part of a file), they still need to be highlighted
    # to ensure that the succeeding lines can be formatted correctly (e.g.
    # multi-line comments).
    all_lines[0..to - 1].join
  end

  def all_lines
    @all_lines ||= blob.data.lines
  end

  def language
    blob.language_from_gitattributes
  end
end

BlobPresenter.prepend_mod_with('BlobPresenter')
