module Projects
  class UploadImage < Projects::Base
    # Why it here?
    include Rails.application.routes.url_helpers

    def setup
      context.fail!(message: 'Invalid repository') if context[:repository].blank?
      context.fail!(message: 'Invalid root url') if context[:root_url].blank?
      context.fail!(message: 'Invalid params') if context[:params].blank?

      if context[:params][:markdown_img].blank?
        context.fail!(message: 'Invalid image')
      end

      unless correct_mime_type?(context[:params][:markdown_img]).blank?
        context.fail!(message: 'Invalid image type')
      end
    end

    def perform
      params = context[:params]
      repository = context[:repository]
      image = params[:markdown_img]

      uploader = FileUploader.new('uploads', upload_path(repository), accepted_images)

      alt = image.original_filename
      uploader.store!(image)

      link = {
        'alt' => File.basename(alt, '.*'),
        'url' => File.join(@root_url, uploader.url)
      }

      context[:link] = link
    end

    def rollback
      # TODO Remove image
      context.delete(:link)
    end

  protected

    def upload_path(repository)
      base_dir = FileUploader.generate_dir
      File.join(repository.path_with_namespace, base_dir)
    end

    def accepted_images
      %w(png jpg jpeg gif)
    end

    def correct_mime_type?(image)
      accepted_images.map{ |format| image.content_type.include? format }.any?
    end
  end
end
