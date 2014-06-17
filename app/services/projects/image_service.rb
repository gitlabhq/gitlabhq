module Projects
  class ImageService < BaseService
    include Rails.application.routes.url_helpers
    def initialize(repository, params, root_url)
      @repository, @params, @root_url = repository, params.dup, root_url
    end

    def execute
      uploader = FileUploader.new('uploads', upload_path, accepted_images)
      image = @params['markdown_img']

      if image && correct_mime_type?(image)
        alt = image.original_filename
        uploader.store!(image)
        link = {
                 'alt' => File.basename(alt, '.*'),
                 'url' => File.join(@root_url, uploader.url) 
               }
      else
        link = nil
      end
    end

  protected

    def upload_path
      base_dir = FileUploader.generate_dir
      File.join(@repository.path_with_namespace, base_dir)
    end

    def accepted_images
      %w(png jpg jpeg gif)
    end

    def correct_mime_type?(image)
      accepted_images.map{ |format| image.content_type.include? format }.any?
    end
  end
end
