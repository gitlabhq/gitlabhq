module Geo
  class FileUploadService
    IAT_LEEWAY = 60.seconds.to_i

    attr_reader :object_type, :object_db_id, :auth_header

    def initialize(params, auth_header)
      @object_type = params[:type]
      @object_db_id = params[:id]
      @auth_header = auth_header
    end

    def execute
      # Returns { code: :ok, file: CarrierWave File object } upon success
      data = ::Gitlab::Geo::JwtRequestDecoder.new(auth_header).decode
      return unless data.present?

      uploader_class.new(object_db_id, data).execute
    end

    private

    def uploader_class
      "Gitlab::Geo::#{object_type.to_s.camelize}Uploader".constantize
    rescue NameError
      Gitlab::Geo::FileUploader
    end
  end
end
