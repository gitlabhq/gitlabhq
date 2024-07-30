# frozen_string_literal: true

class BlobPresenter < Gitlab::View::Presenter::Delegated
  include ApplicationHelper
  include BlobHelper
  include DiffHelper
  include TreeHelper
  include ChecksCollaboration
  include Gitlab::EncodingHelper

  presents ::Blob, as: :blob

  def highlight_and_trim(ellipsis_svg:, trim_length:, plain: nil)
    load_all_blob_data

    trimmed_lines, trimmed_idx = trimmed_blob_data(trim_length)
    Gitlab::Highlight.highlight(
      blob.path,
      trimmed_lines,
      language: blob_language,
      plain: plain,
      context: { ellipsis_indexes: trimmed_idx, ellipsis_svg: ellipsis_svg }
    )
  end

  def highlight(to: nil, plain: nil, used_on: :blob)
    load_all_blob_data

    Gitlab::Highlight.highlight(
      blob.path,
      blob_data(to),
      language: blob_language,
      plain: plain,
      used_on: used_on
    )
  end

  def plain_data
    return if blob.binary?

    highlight(plain: false)
  end

  def trimmed_blob_data(trim_length)
    @_trimmed_blob_data ||= limited_trimmed_blob_data(trim_length)
  end

  def blob_data(to)
    @_blob_data ||= limited_blob_data(to: to)
  end

  def blob_language
    @_blob_language ||= gitattr_language || detect_language
  end

  def raw_plain_data
    blob.data unless blob.binary?
  end

  def web_url
    url_helpers.project_blob_url(*path_params)
  end

  def web_path
    url_helpers.project_blob_path(*path_params)
  end

  def edit_blob_path
    url_helpers.project_edit_blob_path(*path_params)
  end

  def raw_path
    url_helpers.project_raw_path(*path_params)
  end

  def replace_path
    url_helpers.project_update_blob_path(*path_params)
  end

  def pipeline_editor_path
    project_ci_pipeline_editor_path(project, branch_name: commit_id) if can_collaborate_with_project?(project) && blob.path == project.ci_config_path_or_default
  end

  def gitpod_blob_url
    return unless Gitlab::CurrentSettings.gitpod_enabled && !current_user.nil? && current_user.gitpod_enabled

    "#{Gitlab::CurrentSettings.gitpod_url}##{url_helpers.project_tree_url(project, tree_join(blob.commit_id, blob.path || ''))}"
  end

  def find_file_path
    url_helpers.project_find_file_path(project, commit_id, ref_type: ref_type)
  end

  def blame_path
    url_helpers.project_blame_path(*path_params)
  end

  def base64_encoded_blob
    Base64.encode64(blob.raw)
  end

  def history_path
    url_helpers.project_commits_path(*path_params)
  end

  def permalink_path
    url_helpers.project_blob_path(project, File.join(project.repository.commit(blob.commit_id).sha, blob.path))
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

  def fork_and_view_path
    fork_path_for_current_user(project, web_path)
  end

  def can_modify_blob?
    super(blob, project, commit_id)
  end

  def can_modify_blob_with_web_ide?
    super(blob, project)
  end

  def can_current_user_push_to_branch?
    return false unless current_user && project.repository.branch_exists?(commit_id)

    user_access(project).can_push_to_branch?(commit_id)
  end

  def archived?
    project.archived
  end

  def ide_edit_path
    super(project, commit_id, blob.path)
  end

  def external_storage_url
    return unless static_objects_external_storage_enabled?

    external_storage_url_or_path(url_helpers.project_raw_url(project, ref_qualified_path), project)
  end

  def code_navigation_path
    Gitlab::CodeNavigationPath.new(project, blob.commit_id).full_json_path_for(blob.path)
  end

  def project_blob_path_root
    project_blob_path(project, commit_id)
  end

  private

  def path_params
    if ref_type.present?
      [project, ref_qualified_path, { ref_type: ref_type }]
    else
      [project, ref_qualified_path]
    end
  end

  def ref_type
    blob.ref_type
  end

  def url_helpers
    Gitlab::Routing.url_helpers
  end

  def environment
    environment_params = project.repository.branch_exists?(commit_id) ? { ref: commit_id } : { sha: commit_id }
    environment_params[:find_latest] = true
    ::Environments::EnvironmentsByDeploymentsFinder.new(project, current_user, environment_params).execute.last
  end

  def project
    blob.repository.project
  end

  def commit_id
    # If `ref_type` is present the commit_id will include the ref qualifier e.g. `refs/heads/`.
    # We only accept/return unqualified refs so we need to remove the qualifier from the `commit_id`.
    ExtractsRef::RefExtractor.unqualify_ref(blob.commit_id, ref_type)
  end

  def ref_qualified_path
    File.join(commit_id, blob.path)
  end

  def load_all_blob_data
    blob.load_all_data! if blob.respond_to?(:load_all_data!)
  end

  def limited_trimmed_blob_data(trim_length)
    trimmed_idx = []

    trimmed_lines = all_lines.map.with_index do |line, index|
      next line if line.length <= trim_length

      trimmed_idx << index
      "#{line[0, trim_length]}\n"
    end

    [trimmed_lines.join, trimmed_idx]
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

  def gitattr_language
    blob.language_from_gitattributes
  end

  def detect_language
    return if blob.binary?

    Rouge::Lexer.guess(filename: blob.path, source: blob_data(nil)) { |lex| lex.min_by(&:tag) }.tag
  end
end

BlobPresenter.prepend_mod_with('BlobPresenter')
