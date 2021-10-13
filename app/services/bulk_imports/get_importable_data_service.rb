# frozen_string_literal: true

module BulkImports
  class GetImportableDataService
    def initialize(params, query_params, credentials)
      @params = params
      @query_params = query_params
      @credentials = credentials
    end

    def execute
      {
        version_validation: version_validation,
        response: importables
      }
    end

    private

    def importables
      client.get('groups', @query_params)
    end

    def version_validation
      {
        features: {
          project_migration: {
            available: client.compatible_for_project_migration?,
            min_version: BulkImport.min_gl_version_for_project_migration.to_s
          },
          source_instance_version: client.instance_version.to_s
        }
      }
    end

    def client
      @client ||= BulkImports::Clients::HTTP.new(
        url: @credentials[:url],
        token: @credentials[:access_token],
        per_page: @params[:per_page],
        page: @params[:page]
      )
    end
  end
end
