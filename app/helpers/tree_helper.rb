module TreeHelper
  def tree_icon(content)
    if content.is_a?(Grit::Blob)
      if content.text?
        image_tag "file_txt.png"
      elsif content.image?
        image_tag "file_img.png"
      else
        image_tag "file_bin.png"
      end
    else
      image_tag "file_dir.png"
    end
  end

  def tree_hex_class(content)
    "file_#{hexdigest(content.name)}"
  end

  def tree_full_path(content)
    content.name.force_encoding('utf-8')
    if params[:path]
      File.join(params[:path], content.name)
    else
      content.name
    end
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

  # Simple shortcut to File.join
  def tree_join(*args)
    File.join(*args)
  end
end
