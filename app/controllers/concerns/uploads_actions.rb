module UploadsActions
  include Gitlab::Utils::StrongMemoize

  def create
    link_to_file = UploadService.new(model, params[:file], uploader_class).execute

    respond_to do |format|
      if link_to_file
        format.json do
          render json: { link: link_to_file }
        end
      else
        format.json do
          render json: 'Invalid file.', status: :unprocessable_entity
        end
      end
    end
  end

  def show
    return render_404 unless uploader.exists?

    disposition = uploader.image_or_video? ? 'inline' : 'attachment'

    expires_in 0.seconds, must_revalidate: true, private: true

    send_file uploader.file.path, disposition: disposition
  end

  private

  def uploader
    strong_memoize(:uploader) do
      return if show_model.nil?

      file_uploader = FileUploader.new(show_model, params[:secret])
      file_uploader.retrieve_from_store!(params[:filename])

      file_uploader
    end
  end

  def image_or_video?
    uploader && uploader.exists? && uploader.image_or_video?
  end

  def uploader_class
    FileUploader
  end
end
