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

    def log_info(message)
      data = log_base_data(message)
      Gitlab::Geo::Logger.info(data)
    end

    def log_error(message, error)
      data = log_base_data(message)
      data[:error] = error
      Gitlab::Geo::Logger.error(data)
    end

    def log_base_data(message)
      {
        class: self.class.name,
        object_type: object_type,
        object_db_id: object_db_id,
        message: message
      }
    end
  end
end
