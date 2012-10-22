module TreeHelper
  # Sorts a repository's tree so that folders are before files and renders
  # their corresponding partials
  #
  # contents - A Grit::Tree object for the current tree
  def render_tree(contents)
    # Render Folders before Files/Submodules
    folders, files = contents.partition { |v| v.kind_of?(Grit::Tree) }

    tree = ""

    # Render folders if we have any
    tree += render partial: 'tree/tree_item', collection: folders, locals: {type: 'folder'} if folders.present?

    files.each do |f|
      if f.respond_to?(:url)
        # Object is a Submodule
        tree += render partial: 'tree/submodule_item', object: f
      else
        # Object is a Blob
        tree += render partial: 'tree/tree_item', object: f, locals: {type: 'file'}
      end
    end

    tree.html_safe
  end

  # Return an image icon depending on the file type
  #
  # type - String type of the tree item; either 'folder' or 'file'
  def tree_icon(type)
    image = type == 'folder' ? 'file_dir.png' : 'file_txt.png'
    image_tag(image, size: '16x16')
  end

  def tree_hex_class(content)
    "file_#{hexdigest(content.name)}"
  end

  # Public: Determines if a given filename is compatible with GitHub::Markup.
  #
  # filename - Filename string to check
  #
  # Returns boolean
  def markup?(filename)
    filename.end_with?(*%w(.textile .rdoc .org .creole
                           .mediawiki .rst .asciidoc .pod))
  end

  def gitlab_markdown?(filename)
    filename.end_with?(*%w(.mdown .md .markdown))
  end

  def plain_text_readme? filename
    filename == 'README'
  end

  # Simple shortcut to File.join
  def tree_join(*args)
    File.join(*args)
  end

  def allowed_tree_edit?
    if @project.protected_branch? @ref
      can?(current_user, :push_code_to_protected_branches, @project)
    else
      can?(current_user, :push_code, @project)
    end
  end
end
