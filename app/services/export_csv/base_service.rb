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
        CsvBuilder.new(objects.preload(associations_to_preload), header_to_value_hash)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def associations_to_preload
      []
    end

    def header_to_value_hash
      raise NotImplementedError
    end
  end
end
