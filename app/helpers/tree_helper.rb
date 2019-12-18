# frozen_string_literal: true

module TreeHelper
  FILE_LIMIT = 1_000

  # Sorts a repository's tree so that folders are before files and renders
  # their corresponding partials
  #
  # tree - A `Tree` object for the current tree
  # rubocop: disable CodeReuse/ActiveRecord
  def render_tree(tree)
    # Sort submodules and folders together by name ahead of files
    folders, files, submodules = tree.trees, tree.blobs, tree.submodules
    tree = []
    items = (folders + submodules).sort_by(&:name) + files

    if items.size > FILE_LIMIT
      tree << render(partial: 'projects/tree/truncated_notice_tree_row',
                     locals: { limit: FILE_LIMIT, total: items.size })
      items = items.take(FILE_LIMIT)
    end

    tree << render(partial: 'projects/tree/tree_row', collection: items) if items.present?
    tree.join.html_safe
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # Return an image icon depending on the file type and mode
  #
  # type - String type of the tree item; either 'folder' or 'file'
  # mode - File unix mode
  # name - File name
  def tree_icon(type, mode, name)
    icon([file_type_icon_class(type, mode, name), 'fw'])
  end

  # Using Rails `*_path` methods can be slow, especially when generating
  # many paths, as with a repository tree that has thousands of items.
  def fast_project_blob_path(project, blob_path)
    ActionDispatch::Journey::Router::Utils.escape_path(
      File.join(relative_url_root, project.path_with_namespace, 'blob', blob_path)
    )
  end

  def fast_project_tree_path(project, tree_path)
    ActionDispatch::Journey::Router::Utils.escape_path(
      File.join(relative_url_root, project.path_with_namespace, 'tree', tree_path)
    )
  end

  # Simple shortcut to File.join
  def tree_join(*args)
    File.join(*args)
  end

  def on_top_of_branch?(project = @project, ref = @ref)
    project.repository.branch_exists?(ref)
  end

  def can_edit_tree?(project = nil, ref = nil)
    project ||= @project
    ref ||= @ref

    return false unless on_top_of_branch?(project, ref)

    can_collaborate_with_project?(project, ref: ref)
  end

  def tree_edit_branch(project = @project, ref = @ref)
    return unless can_edit_tree?(project, ref)

    if user_access(project).can_push_to_branch?(ref)
      ref
    else
      project = tree_edit_project(project)
      project.repository.next_branch('patch')
    end
  end

  def tree_edit_project(project = @project)
    if can?(current_user, :push_code, project)
      project
    elsif current_user && current_user.already_forked?(project)
      current_user.fork_of(project)
    end
  end

  def edit_in_new_fork_notice_now
    _("You're not allowed to make changes to this project directly. "\
      "A fork of this project is being created that you can make changes in, so you can submit a merge request.")
  end

  def edit_in_new_fork_notice
    _("You're not allowed to make changes to this project directly. "\
      "A fork of this project has been created that you can make changes in, so you can submit a merge request.")
  end

  def edit_in_new_fork_notice_action(action)
    edit_in_new_fork_notice + _(" Try to %{action} this file again.") % { action: action }
  end

  def commit_in_fork_help
    _("A new branch will be created in your fork and a new merge request will be started.")
  end

  def commit_in_single_accessible_branch
    branch_name = ERB::Util.html_escape(selected_branch)

    message = _("Your changes can be committed to %{branch_name} because a merge "\
                "request is open.") % { branch_name: "<strong>#{branch_name}</strong>" }

    message.html_safe
  end

  def path_breadcrumbs(max_links = 6)
    if @path.present?
      part_path = ""
      parts = @path.split('/')

      yield('..', File.join(*parts.first(parts.count - 2))) if parts.count > max_links

      parts.each do |part|
        part_path = File.join(part_path, part) unless part_path.empty?
        part_path = part if part_path.empty?

        next if parts.count > max_links && !parts.last(2).include?(part)

        yield(part, part_path)
      end
    end
  end

  def up_dir_path
    file = File.join(@path, "..")
    tree_join(@ref, file)
  end

  # returns the relative path of the first subdir that doesn't have only one directory descendant
  def flatten_tree(root_path, tree)
    tree.flat_path.sub(%r{\A#{Regexp.escape(root_path)}/}, '')
  end

  def selected_branch
    @branch_name || tree_edit_branch
  end

  def relative_url_root
    Gitlab.config.gitlab.relative_url_root.presence || '/'
  end

  # project and path are used on the EE version
  def tree_content_data(logs_path, project, path)
    {
      "logs-path" => logs_path
    }
  end

  def breadcrumb_data_attributes
    attrs = {
      can_collaborate: can_collaborate_with_project?(@project).to_s,
      new_blob_path: project_new_blob_path(@project, @ref),
      upload_path: project_create_blob_path(@project, @ref),
      new_dir_path: project_create_dir_path(@project, @ref),
      new_branch_path: new_project_branch_path(@project),
      new_tag_path: new_project_tag_path(@project),
      can_edit_tree: can_edit_tree?.to_s
    }

    if can?(current_user, :fork_project, @project) && can?(current_user, :create_merge_request_in, @project)
      continue_param = {
        to: project_new_blob_path(@project, @id),
        notice: edit_in_new_fork_notice,
        notice_now: edit_in_new_fork_notice_now
      }

      attrs.merge!(
        fork_new_blob_path: project_forks_path(@project, namespace_key: current_user.namespace.id, continue: continue_param),
        fork_new_directory_path: project_forks_path(@project, namespace_key: current_user.namespace.id, continue: continue_param.merge({
          to: request.fullpath,
          notice: _("%{edit_in_new_fork_notice} Try to create a new directory again.") % { edit_in_new_fork_notice: edit_in_new_fork_notice }
        })),
        fork_upload_blob_path: project_forks_path(@project, namespace_key: current_user.namespace.id, continue: continue_param.merge({
          to: request.fullpath,
          notice: _("%{edit_in_new_fork_notice} Try to upload a file again.") % { edit_in_new_fork_notice: edit_in_new_fork_notice }
        }))
      )
    end

    attrs
  end

  def vue_file_list_data(project, ref)
    {
      project_path: project.full_path,
      project_short_path: project.path,
      ref: ref,
      full_name: project.name_with_namespace
    }
  end

  def directory_download_links(project, ref, archive_prefix)
    Gitlab::Workhorse::ARCHIVE_FORMATS.map do |fmt|
      {
        text: fmt,
        path: project_archive_path(project, id: tree_join(ref, archive_prefix), format: fmt)
      }
    end
  end
end

TreeHelper.prepend_if_ee('::EE::TreeHelper')
