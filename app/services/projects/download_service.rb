module Projects
  class DownloadService < BaseService

    WHITELIST = [
      /^[^.]+\.fogbugz.com$/
    ]

    def initialize(project, url)
      @project, @url = project, url
    end

    def execute
      return nil unless valid_url?(@url)

      uploader = FileUploader.new(@project)
      uploader.download!(@url)
      uploader.store!

      filename = uploader.image? ? uploader.file.basename : uploader.file.filename

      {
        'alt'       => filename,
        'url'       => uploader.secure_url,
        'is_image'  => uploader.image?
      }
    end

    private

    def valid_url?(url)
      url && http?(url) && valid_domain?(url)
    end

    def http?(url)
      url =~ /\A#{URI::regexp(['http', 'https'])}\z/
    end

    def valid_domain?(url)
      host = URI.parse(url).host
      WHITELIST.any? { |entry| entry === host }
    end
  end
end
