module TreeHelper
  # Sorts a repository's tree so that folders are before files and renders
  # their corresponding partials
  #
  # contents - A Grit::Tree object for the current tree
  def render_tree(tree)
    # Render Folders before Files/Submodules
    folders, files, submodules = tree.trees, tree.blobs, tree.submodules

    tree = ""

    # Render folders if we have any
    tree << render(partial: 'projects/tree/tree_item', collection: folders,
                   locals: { type: 'folder' }) if folders.present?

    # Render files if we have any
    tree << render(partial: 'projects/tree/blob_item', collection: files,
                   locals: { type: 'file' }) if files.present?

    # Render submodules if we have any
    tree << render(partial: 'projects/tree/submodule_item',
                   collection: submodules) if submodules.present?

    tree.html_safe
  end

  def render_readme(readme)
    render_markup(readme.name, readme.data)
  end

  # Return an image icon depending on the file type and mode
  #
  # type - String type of the tree item; either 'folder' or 'file'
  # mode - File unix mode
  # name - File name
  def tree_icon(type, mode, name)
    icon("#{file_type_icon_class(type, mode, name)} fw")
  end

  def tree_hex_class(content)
    "file_#{hexdigest(content.name)}"
  end

  # Simple shortcut to File.join
  def tree_join(*args)
    File.join(*args)
  end

  def allowed_tree_edit?(project = nil, ref = nil)
    project ||= @project
    ref ||= @ref
    return false unless project.repository.branch_names.include?(ref)

    ::Gitlab::GitAccess.new(current_user, project).can_push_to_branch?(ref)
  end

  def tree_breadcrumbs(tree, max_links = 2)
    if @path.present?
      part_path = ""
      parts = @path.split('/')

      yield('..', nil) if parts.count > max_links

      parts.each do |part|
        part_path = File.join(part_path, part) unless part_path.empty?
        part_path = part if part_path.empty?

        next unless parts.last(2).include?(part) if parts.count > max_links
        yield(part, tree_join(@ref, part_path))
      end
    end
  end

  def up_dir_path
    file = File.join(@path, "..")
    tree_join(@ref, file)
  end

  # returns the relative path of the first subdir that doesn't have only one directory descendant
  def flatten_tree(tree)
    subtree = Gitlab::Git::Tree.where(@repository, @commit.id, tree.path)
    if subtree.count == 1 && subtree.first.dir?
      return tree_join(tree.name, flatten_tree(subtree.first))
    else
      return tree.name
    end
  end
end
