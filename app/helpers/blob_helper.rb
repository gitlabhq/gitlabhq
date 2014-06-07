module BlobHelper
  def highlightjs_class(blob_name)
    if blob_name.include?('.')
      ext = blob_name.split('.').last
      return 'language-' + ext
    else
      if no_highlight_files.include?(blob_name.downcase)
        'no-highlight'
      else
        blob_name.downcase
      end
    end
  end

  def no_highlight_files
    %w(credits changelog copying copyright license authors)
  end
end
