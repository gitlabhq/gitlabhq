# frozen_string_literal: true

module Import
  module Offline
    module Exports
      class CreateService
        include ::Gitlab::Utils::StrongMemoize

        # @param current_user [User] current user object
        # @param source_hostname [String] source hostname or alias hostname
        # @param portable_params [Array<Hash>] list of portables to export.
        #   Each portable hash must have at least its type and full path. E.g.:
        #   { type: 'project', full_path: 'gitlab-org/gitlab' }
        # @param storage_config [Hash] contains object storage configuation settings:
        #   provider [Symbol], bucket [String], and credentials [Hash (content varies by provider)]. E.g.:
        #   {
        #     provider: :aws,
        #     bucket: 'import-objects',
        #     credentials: {
        #       aws_access_key_id: 'AwsUserAccessKey',
        #       aws_secret_access_key: 'aws/secret+access/key',
        #       region: 'us-east-1',
        #       path_style: false
        #     }
        #   }
        def initialize(current_user, source_hostname, portable_params, storage_config)
          @current_user = current_user
          @source_hostname = source_hostname
          @portable_params = portable_params
          @storage_config = storage_config
        end

        def execute
          return feature_flag_disabled_error unless Feature.enabled?(:offline_transfer_exports, current_user)
          return invalid_params_error unless portable_params_valid?
          return insufficient_permissions_error unless user_can_export_all_portables?

          validate_object_storage!

          offline_export = Import::Offline::Export.create!(
            user: current_user,
            organization_id: current_user.organization_id,
            source_hostname: source_hostname,
            configuration: configuration
          )

          ServiceResponse.success(payload: offline_export)
        rescue Excon::Error
          # Excon errors may be long and contain sensitive information depending on provider implementation
          service_error(s_('OfflineTransfer|Unable to access object storage bucket.'))
        rescue ActiveRecord::RecordInvalid => e
          service_error(e.message)
        end

        private

        attr_reader :current_user, :source_hostname, :portable_params, :storage_config, :invalid_paths

        def user_can_export_all_portables?
          full_path_params = portable_full_paths
          found_full_paths = groups.map(&:full_path) + projects.map(&:full_path)

          @invalid_paths = full_path_params - found_full_paths

          @invalid_paths += [groups, projects].flatten.filter_map do |portable|
            portable.full_path unless user_can_admin_portable?(portable)
          end

          @invalid_paths.blank?
        end

        def portable_params_valid?
          return false if portable_params.blank?
          return false if portable_params.any? { |h| !h.is_a?(Hash) || h[:type].blank? || h[:full_path].blank? }

          true
        end

        def validate_object_storage!
          configuration.validate! # Validate before attempting to connect using this configuration

          client.test_connection!
        end

        def configuration
          Import::Offline::Configuration.new(
            provider: storage_config[:provider],
            bucket: storage_config[:bucket],
            object_storage_credentials: storage_config[:credentials],
            organization_id: current_user.organization_id
          )
        end
        strong_memoize_attr :configuration

        def client
          Import::Clients::ObjectStorage.new(
            provider: configuration.provider,
            bucket: configuration.bucket,
            credentials: configuration.object_storage_credentials
          )
        end
        strong_memoize_attr :client

        def user_can_admin_portable?(portable)
          ability = "admin_#{portable.to_ability_name}"

          current_user.can?(ability, portable)
        end

        def groups
          Group.where_full_path_in(portable_full_paths)
        end
        strong_memoize_attr :groups

        def projects
          Project.where_full_path_in(portable_full_paths)
        end
        strong_memoize_attr :projects

        def portable_full_paths
          portable_params.map { |params| params[:full_path] }.uniq # rubocop:disable Rails/Pluck -- Not an ActiveRecord object
        end
        strong_memoize_attr :portable_full_paths

        def feature_flag_disabled_error
          service_error('offline_transfer_exports feature flag must be enabled.')
        end

        def invalid_params_error
          service_error(s_('OfflineTransfer|Export failed. Entity types and full paths must be provided.'))
        end

        def insufficient_permissions_error
          service_error(format(
            s_('OfflineTransfer|Export failed. You do not have permission to ' \
              'export the following resources or they do not exist: %{paths}'),
            paths: invalid_paths.join(', ')
          ))
        end

        def service_error(message)
          ServiceResponse.error(
            message: message,
            reason: :unprocessable_entity
          )
        end
      end
    end
  end
end
