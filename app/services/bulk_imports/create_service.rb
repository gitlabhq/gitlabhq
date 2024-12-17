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
      'group_entity' => 'groups',
      'project_entity' => 'projects'
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
        extra: { source_equals_destination: source_equals_destination? }
      )

      if Feature.enabled?(:importer_user_mapping, current_user) &&
          Feature.enabled?(:bulk_import_importer_user_mapping, current_user)
        ::Import::BulkImports::EphemeralData.new(bulk_import.id).enable_importer_user_mapping

        Import::BulkImports::SourceUsersAttributesWorker.perform_async(bulk_import.id)
      end

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
    end

    def create_bulk_import
      BulkImport.transaction do
        bulk_import = BulkImport.create!(
          user: current_user,
          source_type: 'gitlab',
          source_version: client.instance_version,
          source_enterprise: client.instance_enterprise
        )
        bulk_import.create_configuration!(credentials.slice(:url, :access_token))

        Array.wrap(params).each do |entity_params|
          track_access_level(entity_params)

          validate_destination_namespace(entity_params)
          validate_destination_slug(entity_params[:destination_slug] || entity_params[:destination_name])
          validate_destination_full_path(entity_params)

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
        graphql_client.parse(gql_query.to_s),
        { full_path: source_full_path }
      ).original_hash

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
      Gitlab::Tracking.event(
        self.class.name,
        'create',
        label: 'import_access_level',
        user: current_user,
        extra: { user_role: user_role(entity_params[:destination_namespace]), import_type: 'bulk_import_group' }
      )
    end

    def source_equals_destination?
      credentials[:url].starts_with?(Settings.gitlab.base_url)
    end

    def validate_destination_namespace(entity_params)
      destination_namespace = entity_params[:destination_namespace]
      source_type = entity_params[:source_type]

      return if destination_namespace.blank?

      group = Group.find_by_full_path(destination_namespace)
      if group.nil? ||
          (source_type == 'group_entity' && !current_user.can?(:create_subgroup, group)) ||
          (source_type == 'project_entity' && !current_user.can?(:import_projects, group))
        raise BulkImports::Error.destination_namespace_validation_failure(destination_namespace)
      end
    end

    def validate_destination_slug(destination_slug)
      return if Gitlab::Regex.oci_repository_path_regex.match?(destination_slug)

      raise BulkImports::Error.destination_slug_validation_failure
    end

    def validate_destination_full_path(entity_params)
      source_type = entity_params[:source_type]

      full_path = [
        entity_params[:destination_namespace],
        entity_params[:destination_slug] || entity_params[:destination_name]
      ].reject(&:blank?).join('/')

      case source_type
      when 'group_entity'
        return if Namespace.find_by_full_path(full_path).nil?
      when 'project_entity'
        return if Project.find_by_full_path(full_path).nil?
      end

      raise BulkImports::Error.destination_full_path_validation_failure(full_path)
    end

    def user_role(destination_namespace)
      namespace = Namespace.find_by_full_path(destination_namespace)
      # if there is no parent namespace we assume user will be group creator/owner
      return owner_role unless destination_namespace
      return owner_role unless namespace
      return owner_role unless namespace.group_namespace? # user namespace

      membership = current_user.group_members.find_by(source_id: namespace.id) # rubocop:disable CodeReuse/ActiveRecord

      return 'Not a member' unless membership

      Gitlab::Access.human_access(membership.access_level)
    end

    def owner_role
      Gitlab::Access.human_access(Gitlab::Access::OWNER)
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
