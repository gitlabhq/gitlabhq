module BlobRequestFormat
  # We disabled request format for blob-related URLs to be able
  # to use file extensions in a name. That means that we disable all the ways to set
  # a request format. At the same time we want to preserve the way to set format using
  # request parameter. This method uses `blob_format` parameter to set proper format.
  # We don't use a regular `format` name for this parameter as it will be overriden by rails
  # and it will take precendence over custom passed formats as rails does
  # not expect any format parameter at all, since we disabled it.
  def set_blob_request_format
    if params[:blob_format] == 'json'
      request.format = :json
    else
      request.format = :html
    end
  end
end
