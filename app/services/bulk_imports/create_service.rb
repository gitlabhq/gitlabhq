# frozen_string_literal: true

# Entry point of the BulkImport feature.
# This service receives a Gitlab Instance connection params
# and a list of groups to be imported.
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
# - Create a BulkImport::Entity for each group to be imported
# - Enqueue a BulkImportWorker job (P2) to import the given groups (entities)
#
# Pn (async)
#
# - For each group to be imported (BulkImport::Entity.with_status(:created))
#   - Import the group data
#   - Create entities for each subgroup of the imported group
#   - Enqueue a BulkImports::CreateService job (Pn) to import the new entities (subgroups)
#
module BulkImports
  class CreateService
    attr_reader :current_user, :params, :credentials

    def initialize(current_user, params, credentials)
      @current_user = current_user
      @params = params
      @credentials = credentials
    end

    def execute
      validate!

      bulk_import = create_bulk_import

      Gitlab::Tracking.event(self.class.name, 'create', label: 'bulk_import_group')

      BulkImportWorker.perform_async(bulk_import.id)

      ServiceResponse.success(payload: bulk_import)

    rescue ActiveRecord::RecordInvalid, BulkImports::Error, BulkImports::NetworkError => e
      ServiceResponse.error(
        message: e.message,
        http_status: :unprocessable_entity
      )
    end

    private

    def validate!
      client.validate_instance_version!
      client.validate_import_scopes!
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

        Array.wrap(params).each do |entity|
          track_access_level(entity)

          BulkImports::Entity.create!(
            bulk_import: bulk_import,
            source_type: entity[:source_type],
            source_full_path: entity[:source_full_path],
            destination_slug: entity[:destination_slug],
            destination_namespace: entity[:destination_namespace],
            migrate_projects: Gitlab::Utils.to_boolean(entity[:migrate_projects], default: true)
          )
        end

        bulk_import
      end
    end

    def track_access_level(entity)
      Gitlab::Tracking.event(
        self.class.name,
        'create',
        label: 'import_access_level',
        user: current_user,
        extra: { user_role: user_role(entity[:destination_namespace]), import_type: 'bulk_import_group' }
      )
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
  end
end
