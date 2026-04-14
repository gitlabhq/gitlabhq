# frozen_string_literal: true

module Import
  module BulkImports
    class MaxIidsExportService
      include Gitlab::ImportExport::CommandLineUtil

      RELATION = 'max_iids'

      # Accepts the same constructor signature as TreeExportService and
      # FileExportService for compatibility with ExportUploadable#export_service.
      # The relation and user parameters are not used.
      def initialize(portable, export_path, _relation = nil, _user = nil)
        @portable = portable
        @export_path = export_path
      end

      def execute
        mkdir_p(export_path)

        json_writer = Gitlab::ImportExport::Json::NdjsonWriter.new(export_path)
        json_writer.write_attributes(RELATION, compute_max_iids)
      end

      def exported_filename
        "#{RELATION}.json"
      end

      def exported_objects_count
        1
      end

      private

      attr_reader :portable, :export_path

      def compute_max_iids
        resource_queries.each_with_object({}) do |(resource, query), result|
          max = query.call(portable)
          result[resource.to_s] = max if max
        end
      end

      def resource_queries
        case portable
        when Project
          ::Gitlab::ImportExport::Project::MaxIidsSaver.resource_queries
        when Group
          ::Gitlab::ImportExport::Group::MaxIidsSaver.resource_queries
        else
          Gitlab::AppLogger.warn(message: 'MaxIidsExportService: unsupported portable type',
            portable_type: portable.class.name)
          {}
        end
      end
    end
  end
end
