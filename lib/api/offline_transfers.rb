# frozen_string_literal: true

module API
  class OfflineTransfers < ::API::Base
    include PaginationParams

    feature_category :importers
    urgency :low # Allow more time to validate migration config for immediate user feedback in API responses

    helpers do
      params :object_storage_configuration_params do
        requires :bucket, type: String, desc: 'Name of the object storage bucket where export data is stored'
        optional :aws_s3_configuration, type: Hash, desc: 'AWS S3 object storage configuration' do
          requires :aws_access_key_id, type: String, desc: 'AWS S3 access key ID'
          requires :aws_secret_access_key, type: String, desc: 'AWS S3 secret access key'
          requires :region, type: String, desc: 'AWS S3 object storage region'
          optional :path_style, type: Boolean, default: false,
            desc: 'Use path-style URLs instead of virtual-hosted-style URLs'
        end
        optional :s3_compatible_configuration,
          type: Hash,
          desc: 'MinIO or other S3-compatible object storage configuration' do
          requires :aws_access_key_id, type: String, desc: 'S3-compatible access key ID'
          requires :aws_secret_access_key, type: String, desc: 'S3-compatible secret access key'
          requires :region, type: String, desc: 'S3-compatible object storage region'
          requires :endpoint, type: String, desc: 'Object storage location endpoint'
          optional :path_style, type: Boolean, default: true,
            desc: 'Use path-style URLs instead of virtual-hosted-style URLs'
        end
        exactly_one_of :aws_s3_configuration, :s3_compatible_configuration
      end

      def offline_exports
        @offline_exports ||= ::Import::Offline::ExportsFinder.new(
          user: current_user,
          params: params.slice(:sort, :status)
        ).execute
      end

      def offline_export
        @offline_export ||= offline_exports.find(params[:id])
      end
    end

    before do
      authenticate!
    end

    resource :offline_exports do
      before do
        not_found! unless Feature.enabled?(:offline_transfer_exports, current_user)
      end

      desc 'Start a new offline transfer export' do
        detail 'Initiates a new offline transfer export'
        tags ['offline_transfers']
      end
      params do
        use :object_storage_configuration_params
        requires :entities, type: Array, desc: 'List of entities to export' do
          requires :full_path,
            type: String,
            desc: 'Relative path of the entity to export',
            documentation: { example: "'source/full/path' not 'https://example.com/source/full/path'" }
        end
      end
      post do
        check_rate_limit!(:offline_export, scope: current_user)

        storage_config = { bucket: declared_params[:bucket] }
        if params[:aws_s3_configuration]
          storage_config.merge!(provider: :aws, credentials: declared_params[:aws_s3_configuration])
        end

        if params[:s3_compatible_configuration]
          storage_config.merge!(provider: :s3_compatible, credentials: declared_params[:s3_compatible_configuration])
        end

        set_current_organization
        response = ::Import::Offline::Exports::CreateService.new(
          current_user,
          declared_params[:entities],
          storage_config,
          Current.organization.id
        ).execute

        if response.success?
          present response.payload, with: Entities::Import::Offline::Export
        else
          render_api_error!(response.message, response.reason)
        end
      end

      desc 'List all offline transfer exports' do
        detail 'Lists all offline transfer exports'
        tags ['offline_transfers']
      end
      params do
        use :pagination
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
          desc: 'Return offline transfer exports sorted in created by `asc` or `desc` order.'
        optional :status, type: String, values: Import::Offline::Export.all_human_statuses,
          desc: 'Return offline transfer exports with specified status'
      end
      get do
        present paginate(offline_exports), with: Entities::Import::Offline::Export
      end

      desc 'Get offline transfer export details' do
        detail 'Retrieves details of an offline transfer export'
        tags ['offline_transfers']
      end
      params do
        requires :id, type: Integer, desc: "The ID of user's offline transfer export"
      end
      get ':id' do
        present offline_export, with: Entities::Import::Offline::Export
      end
    end

    resource :offline_imports do
      desc 'Start a new offline transfer import' do
        detail 'Initiates a new offline transfer import from object storage'
        success code: 201, model: Entities::BulkImport
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' },
          { code: 429, message: 'Too many requests' }
        ]
        tags ['offline_transfers']
      end
      params do
        use :object_storage_configuration_params
        requires :export_prefix, type: String, desc: 'Prefix of the export within the bucket'
        requires :entities, type: Array, desc: 'List of entities to import' do
          requires :source_type, type: String, values: %w[group_entity project_entity],
            desc: 'Type of the entity to import'
          requires :source_full_path, type: String, desc: 'Full path of the entity on the source instance'
          requires :destination_namespace, type: String, desc: 'Full path of the destination namespace'
          optional :destination_slug, type: String, desc: 'Destination slug for the imported entity'
        end
      end
      route_setting :authorization, permissions: :create_offline_import, boundary_type: :instance
      post do
        not_found! unless Feature.enabled?(:offline_transfer_imports, current_user)

        check_rate_limit!(:offline_import, scope: current_user)

        storage_config = {
          bucket: declared_params[:bucket],
          export_prefix: declared_params[:export_prefix]
        }

        if params[:aws_s3_configuration]
          storage_config.merge!(provider: :aws, object_storage_credentials: declared_params[:aws_s3_configuration])
        end

        if params[:s3_compatible_configuration]
          storage_config.merge!(
            provider: :s3_compatible,
            object_storage_credentials: declared_params[:s3_compatible_configuration]
          )
        end

        set_current_organization
        response = ::Import::Offline::Imports::CreateService.new(
          storage_config,
          declared_params.slice(:entities),
          current_user: current_user,
          fallback_organization: Current.organization
        ).execute

        if response.success?
          present response.payload, with: Entities::BulkImport
        else
          render_api_error!(response.message, response.reason)
        end
      end
    end
  end
end
