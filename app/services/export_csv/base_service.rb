# frozen_string_literal: true

module ExportCsv
  class BaseService
    # Target attachment size before base64 encoding
    TARGET_FILESIZE = 15.megabytes

    def initialize(relation, resource_parent = nil, fields = [])
      @objects = relation
      @resource_parent = resource_parent
      @fields = fields
    end

    def csv_data
      csv_builder.render(TARGET_FILESIZE)
    end

    def email(user)
      raise NotImplementedError
    end

    def invalid_fields
      ::ExportCsv::MapExportFieldsService.new(fields, header_to_value_hash).invalid_fields
    end

    private

    attr_reader :resource_parent, :objects, :fields

    # rubocop: disable CodeReuse/ActiveRecord
    def csv_builder
      @csv_builder ||= begin
        data_hash = MapExportFieldsService.new(fields, header_to_value_hash).execute

        if preload_associations_in_batches?
          collection = KeysetCollection.new(
            objects,
            associations_to_preload: associations_to_preload,
            on_batch_loaded: method(:on_batch_loaded)
          )
          CsvBuilder.new(collection, data_hash)
        else
          CsvBuilder.new(objects.preload(associations_to_preload), data_hash, [])
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def associations_to_preload
      []
    end

    def header_to_value_hash
      raise NotImplementedError
    end

    def preload_associations_in_batches?
      false
    end

    def on_batch_loaded(_records); end
  end
end
