# frozen_string_literal: true

module API
  class OfflineTransfers < ::API::Base
    include PaginationParams

    feature_category :importers
    urgency :low # Allow more time to validate migration config for immediate user feedback in API responses

    helpers do
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
      not_found! unless Feature.enabled?(:offline_transfer_exports, current_user)

      authenticate!
    end

    resource :offline_exports do
      desc 'Start a new offline transfer export'
      params do
        requires :bucket, type: String, desc: 'Name of the object storage bucket where export data is stored'
        optional :aws_s3_configuration, type: Hash, desc: 'AWS S3 object storage configuration' do
          requires :aws_access_key_id, type: String, desc: 'AWS S3 access key ID'
          requires :aws_secret_access_key, type: String, desc: 'AWS S3 secret access key'
          requires :region, type: String, desc: 'AWS S3 object storage region'
          optional :path_style, type: Boolean, default: false,
            desc: 'Use path-style URLs instead of virtual hosted-style URLs'
        end
        optional :s3_compatible_configuration,
          type: Hash,
          desc: 'MinIO or other S3-compatible object storage configuration' do
          requires :aws_access_key_id, type: String, desc: 'S3-compatible access key ID'
          requires :aws_secret_access_key, type: String, desc: 'S3-compatible secret access key'
          requires :region, type: String, desc: 'S3-compatible object storage region'
          requires :endpoint, type: String, desc: 'Object storage location endpoint'
          optional :path_style, type: Boolean, default: true,
            desc: 'Use path-style URLs instead of virtual hosted-style URLs'
        end
        requires :entities, type: Array, desc: 'List of entities to export' do
          requires :full_path,
            type: String,
            desc: 'Relative path of the entity to export',
            documentation: { example: "'source/full/path' not 'https://example.com/source/full/path'" }
        end

        exactly_one_of :aws_s3_configuration, :s3_compatible_configuration
      end
      post do
        check_rate_limit!(:offline_export, scope: current_user)

        storage_config = { bucket: declared_params[:bucket] }
        if params[:aws_s3_configuration]
          storage_config.merge!(provider: :aws, credentials: declared_params[:aws_s3_configuration])
        end
        # We've previously validated that only one of :aws_s3_configuration, :s3_compatible_configuration
        # should be set, but having two individual 'if' statements eliminates the need to introduce and
        # test the unnecessary 'then' case.
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

      desc 'List all offline transfer exports'
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

      desc 'Get offline transfer export details'
      params do
        requires :id, type: Integer, desc: "The ID of user's offline transfer export"
      end
      get ':id' do
        present offline_export, with: Entities::Import::Offline::Export
      end
    end
  end
end
