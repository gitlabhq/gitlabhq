# frozen_string_literal: true

module SendFileUpload
  def send_upload(file_upload, send_params: {}, redirect_params: {}, attachment: nil, proxy: false, disposition: 'attachment')
    if attachment
      response_disposition = ::Gitlab::ContentDisposition.format(disposition: 'attachment', filename: attachment)

      # Response-Content-Type will not override an existing Content-Type in
      # Google Cloud Storage, so the metadata needs to be cleared on GCS for
      # this to work. However, this override works with AWS.
      redirect_params[:query] = { "response-content-disposition" => response_disposition,
                                  "response-content-type" => guess_content_type(attachment) }
      # By default, Rails will send uploads with an extension of .js with a
      # content-type of text/javascript, which will trigger Rails'
      # cross-origin JavaScript protection.
      send_params[:content_type] = 'text/plain' if File.extname(attachment) == '.js'

      send_params.merge!(filename: attachment, disposition: utf8_encoded_disposition(disposition, attachment))
    end

    if file_upload.file_storage?
      send_file file_upload.path, send_params
    elsif file_upload.class.proxy_download_enabled? || proxy
      headers.store(*Gitlab::Workhorse.send_url(file_upload.url(**redirect_params)))
      head :ok
    else
      redirect_to file_upload.url(**redirect_params)
    end
  end

  # Since Rails 5 doesn't properly support support non-ASCII filenames,
  # we have to add our own to ensure RFC 5987 compliance. However, Rails
  # 5 automatically appends `filename#{filename}` here:
  # https://github.com/rails/rails/blob/v5.0.7/actionpack/lib/action_controller/metal/data_streaming.rb#L137
  # Rails 6 will have https://github.com/rails/rails/pull/33829, so we
  # can get rid of this special case handling when we upgrade.
  def utf8_encoded_disposition(disposition, filename)
    content = ::Gitlab::ContentDisposition.new(disposition: disposition, filename: filename)

    "#{disposition}; #{content.utf8_filename}"
  end

  def guess_content_type(filename)
    types = MIME::Types.type_for(filename)

    if types.present?
      types.first.content_type
    else
      "application/octet-stream"
    end
  end
end
