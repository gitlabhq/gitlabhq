# frozen_string_literal: true

module ExportCsv
  class BaseService
    # Target attachment size before base64 encoding
    TARGET_FILESIZE = 15.megabytes

    def initialize(relation, resource_parent)
      @objects = relation
      @resource_parent = resource_parent
    end

    def csv_data
      csv_builder.render(TARGET_FILESIZE)
    end

    def email(user)
      raise NotImplementedError
    end

    private

    attr_reader :resource_parent, :objects

    # rubocop: disable CodeReuse/ActiveRecord
    def csv_builder
      @csv_builder ||=
        if preload_associations_in_batches?
          CsvBuilder.new(objects, header_to_value_hash, associations_to_preload)
        else
          CsvBuilder.new(objects.preload(associations_to_preload), header_to_value_hash, [])
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
  end
end
