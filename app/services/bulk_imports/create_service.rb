# frozen_string_literal: true

# Entry point of the BulkImport/Direct Transfer feature.
# This service receives a Gitlab Instance connection params
# and a list of groups or projects to be imported.
#
# Process topography:
#
#       sync      |   async
#                 |
#  User +--> P1 +----> Pn +---+
#                 |     ^     | Enqueue new job
#                 |     +-----+
#
# P1 (sync)
#
# - Create a BulkImport record
# - Create a BulkImport::Entity for each group or project (entities) to be imported
# - Enqueue a BulkImportWorker job (P2) to import the given entity
#
# Pn (async)
#
# - For each group to be imported (BulkImport::Entity.with_status(:created))
#   - Import the group data
#   - Create entities for each subgroup of the imported group
#   - Create entities for each project of the imported group
#   - Enqueue a BulkImportWorker job (Pn) to import the new entities

module BulkImports
  class CreateService
    ENTITY_TYPES_MAPPING = {
      Entity::GROUP_ENTITY_SOURCE_TYPE => 'groups',
      Entity::PROJECT_ENTITY_SOURCE_TYPE => 'projects'
    }.freeze

    attr_reader :current_user, :params, :credentials, :fallback_organization

    def initialize(current_user, params, credentials, fallback_organization:)
      @current_user = current_user
      @fallback_organization = fallback_organization
      @params = params
      @credentials = credentials
    end

    def execute
      validate!

      bulk_import = create_bulk_import

      Gitlab::Tracking.event(
        self.class.name,
        'create',
        label: 'bulk_import_group',
        extra: { source_equals_destination: bulk_import.source_equals_destination? }
      )

      ::Import::BulkImports::EphemeralData.new(bulk_import.id).enable_importer_user_mapping
      ::Import::BulkImports::SourceUsersAttributesWorker.perform_async(bulk_import.id)

      BulkImportWorker.perform_async(bulk_import.id)

      ServiceResponse.success(payload: bulk_import)
    rescue ActiveRecord::RecordInvalid, BulkImports::Error, BulkImports::NetworkError => e
      ServiceResponse.error(
        message: e.message,
        http_status: :unprocessable_entity
      )
    end

    private

    attr_accessor :source_entity_identifier

    def validate!
      client.validate_instance_version!
      client.validate_import_scopes!
      validate_source_full_path!
      validate_setting_enabled!
      validate_import_destinations!
    end

    def create_bulk_import
      BulkImport.transaction do
        bulk_import = BulkImport.create!(
          user: current_user,
          source_type: 'gitlab',
          source_version: client.instance_version,
          source_enterprise: client.instance_enterprise,
          # All imported groups must have the same organization, so we can safely fetch from the first
          organization: organization(params.dig(0, :destination_namespace))
        )
        bulk_import.create_configuration!(credentials.slice(:url, :access_token))

        Array.wrap(params).each do |entity_params|
          BulkImports::Entity.create!(
            bulk_import: bulk_import,
            organization: organization(entity_params[:destination_namespace]),
            source_type: entity_params[:source_type],
            source_full_path: entity_params[:source_full_path],
            destination_slug: entity_params[:destination_slug] || entity_params[:destination_name],
            destination_namespace: entity_params[:destination_namespace],
            migrate_projects: Gitlab::Utils.to_boolean(entity_params[:migrate_projects], default: true),
            migrate_memberships: Gitlab::Utils.to_boolean(entity_params[:migrate_memberships], default: true)
          )
        end
        bulk_import
      end
    end

    def validate_source_full_path!
      gql_query = query_type(entity_type)

      response = graphql_client.execute(
        query: gql_query.to_s,
        variables: { full_path: source_full_path }
      )

      self.source_entity_identifier = ::GlobalID.parse(response.dig(*gql_query.data_path, 'id'))&.model_id

      raise BulkImports::Error.source_full_path_validation_failure(source_full_path) if source_entity_identifier.nil?
    end

    def validate_setting_enabled!
      client.get("/#{entity_type}/#{source_entity_identifier}/export_relations/status")
    rescue BulkImports::NetworkError => e
      raise BulkImports::Error.not_authorized(source_full_path) if e.message.include?("URL is blocked")
      raise BulkImports::Error.setting_not_enabled if e.response.code == 404
      raise BulkImports::Error.not_authorized(source_full_path) if e.response.code == 403

      raise e
    end

    def organization(namespace)
      @organization ||= { '' => fallback_organization }
      @organization[namespace] ||= Group.find_by_full_path(namespace)&.organization || fallback_organization
    end

    def entity_type
      @entity_type ||= ENTITY_TYPES_MAPPING.fetch(Array.wrap(params)[0][:source_type])
    end

    def source_full_path
      @source_full_path ||= Array.wrap(params)[0][:source_full_path]
    end

    def track_access_level(entity_params)
      ::Import::Framework::UserRoleTracker
        .new(current_user: current_user, tracking_class_name: self.class.name, import_type: 'bulk_import_group')
        .track(entity_params[:destination_namespace])
    end

    def validate_import_destinations!
      Array.wrap(params).each do |entity_params|
        track_access_level(entity_params)

        destination_validator.validate!(
          entity_params[:destination_namespace],
          entity_params[:destination_slug],
          entity_params[:destination_name],
          entity_params[:source_type]
        )
      end
    end

    def destination_validator
      @destination_validator ||= ::Import::Framework::DestinationValidator.new(current_user: current_user)
    end

    def client
      @client ||= BulkImports::Clients::HTTP.new(
        url: @credentials[:url],
        token: @credentials[:access_token]
      )
    end

    def graphql_client
      @graphql_client ||= BulkImports::Clients::Graphql.new(
        url: @credentials[:url],
        token: @credentials[:access_token]
      )
    end

    def query_type(entity_type)
      if entity_type == 'groups'
        BulkImports::Groups::Graphql::GetGroupQuery.new(context: nil)
      else
        BulkImports::Projects::Graphql::GetProjectQuery.new(context: nil)
      end
    end
  end
end
