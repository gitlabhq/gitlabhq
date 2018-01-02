module Geo
  class FileUploadService < FileService
    IAT_LEEWAY = 60.seconds.to_i

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
