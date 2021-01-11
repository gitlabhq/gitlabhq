# frozen_string_literal: true

module Issuable
  module ExportCsv
    class BaseService
      # Target attachment size before base64 encoding
      TARGET_FILESIZE = 15.megabytes

      def initialize(issuables_relation, project)
        @issuables = issuables_relation
        @project = project
      end

      def csv_data
        csv_builder.render(TARGET_FILESIZE)
      end

      private

      attr_reader :project, :issuables

      # rubocop: disable CodeReuse/ActiveRecord
      def csv_builder
        @csv_builder ||=
          CsvBuilder.new(issuables.preload(associations_to_preload), header_to_value_hash)
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
end
