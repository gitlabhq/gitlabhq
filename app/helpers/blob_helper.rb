module BlobHelper
  def highlightjs_class(blob_name)
    if no_highlight_files.include?(blob_name.downcase)
      'no-highlight'
    else
      blob_name.downcase
    end
  end

  def no_highlight_files
    %w(credits changelog copying copyright license authors)
  end
end
