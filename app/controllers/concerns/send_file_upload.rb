module SendFileUpload
  def send_upload(file_upload, send_params: {}, redirect_params: {}, attachment: nil, disposition: 'attachment')
    if attachment
      redirect_params[:query] = { "response-content-disposition" => "#{disposition};filename=#{attachment.inspect}" }
      # By default, Rails will send uploads with an extension of .js with a
      # content-type of text/javascript, which will trigger Rails'
      # cross-origin JavaScript protection.
      send_params[:content_type] = 'text/plain' if File.extname(attachment) == '.js'
      send_params.merge!(filename: attachment, disposition: disposition)
    end

    if file_upload.file_storage?
      send_file file_upload.path, send_params
    elsif file_upload.class.proxy_download_enabled?
      headers.store(*Gitlab::Workhorse.send_url(file_upload.url(**redirect_params)))
      head :ok
    else
      redirect_to file_upload.url(**redirect_params)
    end
  end
end
