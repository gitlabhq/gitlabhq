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
    if params[:path] 
      File.join(params[:path], content.name)
    else
      content.name
    end
  end
end
