module Geo
  # This class is responsible for:
  #   * Handling file requests from the secondary over the API
  #   * Returning the necessary response data to send the file back
  class FileUploadService < FileService
    attr_reader :auth_header

    def initialize(params, auth_header)
      super(params[:type], params[:id])
      @auth_header = auth_header
    end

    def execute
      # Returns { code: :ok, file: CarrierWave File object } upon success
      data = ::Gitlab::Geo::JwtRequestDecoder.new(auth_header).decode
      return unless data.present?

      uploader_klass.new(object_db_id, data).execute
    end

    private

    def uploader_klass
      "Gitlab::Geo::#{service_klass_name}Uploader".constantize
    rescue NameError => e
      log_error('Unknown file type', e)
      raise
    end
  end
end
