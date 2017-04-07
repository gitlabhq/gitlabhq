module Geo
  class FileService
    attr_reader :object_type, :object_db_id

    DEFAULT_OBJECT_TYPES = %w[attachment avatar file].freeze
    DEFAULT_SERVICE_TYPE = 'file'.freeze

    def initialize(object_type, object_db_id)
      @object_type = object_type.to_s
      @object_db_id = object_db_id
    end

    def execute
      raise NotImplementedError
    end

    private

    def service_klass_name
      klass_name =
        if DEFAULT_OBJECT_TYPES.include?(object_type)
          DEFAULT_SERVICE_TYPE
        else
          object_type
        end

      klass_name.camelize
    end

    def log(message)
      Rails.logger.info "#{self.class.name}: #{message}"
    end
  end
end
