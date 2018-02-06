module EE
  module JobArtifactUploader
    extend ActiveSupport::Concern

    def open
      if file_storage?
        super
      else
        ::Gitlab::Ci::Trace::HttpIO.new(url, size) if url
      end
    end
  end
end
