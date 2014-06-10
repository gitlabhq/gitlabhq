module Projects
  class FileService < BaseService
    include Rails.application.routes.url_helpers
    def initialize(repository, params, root_url)
      @repository, @params, @root_url = repository, params.dup, root_url
    end

    def execute
      uploader = FileUploader.new('uploads', upload_path, accepted_files)
      file = @params['markdown_file']

      if file
        alt = file.original_filename
        uploader.store!(file)
        link = {
                 'alt' => File.basename(alt, '.*'),
                 'url' => File.join(@root_url, uploader.url),
                 'is_image' => image?(file)
               }
      else
        link = nil
      end
    end

    protected

    def accepted_files
      # insert accepted mime types here (e.g %w(jpg jpeg gif png))
      nil
    end

    def accepted_images
      %w(jpg jpeg gif png)
    end

    def image?(file)
      accepted_images.map { |format| file.content_type.include? format }.any?
    end

    def upload_path
      base_dir = FileUploader.generate_dir
      File.join(@repository.path_with_namespace, base_dir)
    end

    def correct_mime_type?(file)
      accepted_files.map { |format| image.content_type.include? format }.any?
    end
  end
end
