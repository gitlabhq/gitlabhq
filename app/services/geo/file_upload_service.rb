module Geo
  class FileUploadService
    DEFAULT_OBJECT_TYPES = [:attachment, :avatar, :file].freeze
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

      uploader_klass.new(object_db_id, data).execute
    end

    private

    def uploader_klass
      uploader_klass_name.constantize
    rescue NameError
      log("Unknown file type: #{object_type}")
      raise
    end

    def uploader_klass_name
      klass_name =
        if DEFAULT_OBJECT_TYPES.include?(object_type.to_sym)
          :file
        else
          object_type
        end

      "Gitlab::Geo::#{klass_name.to_s.camelize}Uploader"
    end

    def log(message)
      Rails.logger.info "#{self.class.name}: #{message}"
    end
  end
end
