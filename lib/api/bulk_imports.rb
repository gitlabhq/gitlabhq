# frozen_string_literal: true

module API
  class BulkImports < ::API::Base
    include PaginationParams

    feature_category :importers
    urgency :low

    helpers do
      def bulk_imports
        @bulk_imports ||= ::BulkImports::ImportsFinder.new(
          user: current_user,
          params: params.merge(include_configuration: true)
        ).execute
      end

      def bulk_import
        @bulk_import ||= bulk_imports.find(params[:import_id])
      end

      def bulk_import_entities
        @bulk_import_entities ||= ::BulkImports::EntitiesFinder.new(
          user: current_user,
          bulk_import: bulk_import,
          params: params
        ).execute
      end

      def bulk_import_entity
        @bulk_import_entity ||= bulk_import_entities.find(params[:entity_id])
      end
    end

    before do
      not_found! unless Gitlab::CurrentSettings.bulk_import_enabled?

      authenticate!
    end

    resource :bulk_imports do
      desc 'Start a new GitLab Migration' do
        detail 'This feature was introduced in GitLab 14.2.'
        success code: 200, model: Entities::BulkImport
        consumes ['application/x-www-form-urlencoded']
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      params do
        requires :configuration, type: Hash, desc: 'The source GitLab instance configuration' do
          requires :url, type: String, desc: 'Source GitLab instance URL'
          requires :access_token, type: String, desc: 'Access token to the source GitLab instance'
        end
        requires :entities, type: Array, desc: 'List of entities to import' do
          requires :source_type,
            type: String,
            desc: 'Source entity type',
            values: %w[group_entity project_entity]
          requires :source_full_path,
            type: String,
            desc: 'Relative path of the source entity to import',
            source_full_path: true,
            documentation: { example: "'source/full/path' not 'https://example.com/source/full/path'" }
          requires :destination_namespace,
            type: String,
            desc: 'Destination namespace for the entity',
            destination_namespace_path: true,
            documentation: { example: "'destination_namespace' or 'destination/namespace'" }
          optional :destination_slug,
            type: String,
            desc: 'Destination slug for the entity',
            destination_slug_path: true,
            documentation: { example: "'destination_slug' not 'destination/slug'" }
          optional :destination_name,
            type: String,
            desc: 'Deprecated: Use :destination_slug instead. Destination slug for the entity',
            destination_slug_path: true,
            documentation: { example: "'destination_slug' not 'destination/slug'" }
          optional :migrate_projects,
            type: Boolean,
            default: true,
            desc: 'Indicates group migration should include nested projects'
          optional :migrate_memberships,
            type: Boolean,
            default: true,
            desc: 'The option to migrate memberships or not'

          mutually_exclusive :destination_slug, :destination_name
          at_least_one_of :destination_slug, :destination_name
        end
      end
      post do
        check_rate_limit!(:bulk_import, scope: current_user)

        params[:entities].each do |entity|
          if entity[:destination_name]
            entity[:destination_slug] ||= entity[:destination_name]
            entity.delete(:destination_name)
          end
        end

        set_current_organization
        response = ::BulkImports::CreateService.new(
          current_user,
          params[:entities],
          params[:configuration].slice(:url, :access_token),
          fallback_organization: Current.organization
        ).execute

        if response.success?
          present response.payload, with: Entities::BulkImport
        else
          render_api_error!(response.message, response.http_status)
        end
      end

      desc 'List all GitLab Migrations' do
        detail 'This feature was introduced in GitLab 14.1.'
        is_array true
        success code: 200, model: Entities::BulkImport
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      params do
        use :pagination
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
          desc: 'Return GitLab Migrations sorted in created by `asc` or `desc` order.'
        optional :status, type: String, values: BulkImport.all_human_statuses,
          desc: 'Return GitLab Migrations with specified status'
      end
      get do
        present paginate(bulk_imports), with: Entities::BulkImport
      end

      desc "List all GitLab Migrations' entities" do
        detail 'This feature was introduced in GitLab 14.1.'
        is_array true
        success code: 200, model: Entities::BulkImports::Entity
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      params do
        use :pagination
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
          desc: 'Return GitLab Migrations sorted in created by `asc` or `desc` order.'
        optional :status, type: String, values: ::BulkImports::Entity.all_human_statuses,
          desc: "Return all GitLab Migrations' entities with specified status"
      end
      get :entities do
        entities = ::BulkImports::EntitiesFinder.new(
          user: current_user,
          params: params
        ).execute

        present paginate(entities), with: Entities::BulkImports::Entity
      end

      desc 'Get GitLab Migration details' do
        detail 'This feature was introduced in GitLab 14.1.'
        success code: 200, model: Entities::BulkImport
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      params do
        requires :import_id, type: Integer, desc: "The ID of user's GitLab Migration"
      end
      get ':import_id' do
        present bulk_import, with: Entities::BulkImport
      end

      desc "List GitLab Migration entities" do
        detail 'This feature was introduced in GitLab 14.1.'
        is_array true
        success code: 200, model: Entities::BulkImports::Entity
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      params do
        requires :import_id, type: Integer, desc: "The ID of user's GitLab Migration"
        optional :status, type: String, values: ::BulkImports::Entity.all_human_statuses,
          desc: 'Return import entities with specified status'
        use :pagination
      end
      get ':import_id/entities' do
        present paginate(bulk_import_entities), with: Entities::BulkImports::Entity
      end

      desc 'Get GitLab Migration entity details' do
        detail 'This feature was introduced in GitLab 14.1.'
        success code: 200, model: Entities::BulkImports::Entity
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      params do
        requires :import_id, type: Integer, desc: "The ID of user's GitLab Migration"
        requires :entity_id, type: Integer, desc: "The ID of GitLab Migration entity"
      end
      get ':import_id/entities/:entity_id' do
        present bulk_import_entity, with: Entities::BulkImports::Entity
      end

      desc 'Get GitLab Migration entity failures' do
        detail 'This feature was introduced in GitLab 16.6'
        success code: 200, model: Entities::BulkImports::EntityFailure
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      params do
        requires :import_id, type: Integer, desc: "The ID of user's GitLab Migration"
        requires :entity_id, type: Integer, desc: "The ID of GitLab Migration entity"
      end
      get ':import_id/entities/:entity_id/failures' do
        present paginate(bulk_import_entity.failures), with: Entities::BulkImports::EntityFailure
      end

      desc 'Cancel GitLab Migration' do
        detail 'This feature was introduced in GitLab 17.1'
        success code: 200, model: Entities::BulkImport
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
      end

      params do
        requires :import_id, type: Integer, desc: "The ID of user's GitLab Migration"
      end
      post ':import_id/cancel' do
        bulk_import = BulkImport.find_by_id(params[:import_id])

        not_found! unless bulk_import
        authenticated_as_admin! unless bulk_import.user == current_user

        bulk_import.cancel!

        status :ok
        present bulk_import, with: Entities::BulkImport
      end
    end
  end
end
