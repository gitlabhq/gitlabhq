# frozen_string_literal: true

module Import
  module Offline
    class Configuration < ApplicationRecord
      self.table_name = 'import_offline_configurations'

      S3_BUCKET_REGEXP = %r{\A[a-z0-9.\-]*\z}

      # The only fields fog-google needs to authenticate with a service account
      # key. The API accepts the key as a pasted JSON string, which we flatten
      # into these individual credential fields (see #flatten_gcs_json_key) and
      # keep only these, for two reasons:
      #   - we never persist credential data we do not use; and
      #   - some key fields (for example universe_domain and token_uri) tell the
      #     Google auth libraries which host to send the token-exchange and storage
      #     requests to. The key is user-supplied, so honoring those would let a
      #     caller point GitLab's outbound requests at a host they control (SSRF,
      #     with forged responses), so we drop them and rely on the defaults. This
      #     integration only ever targets commercial Google Cloud.
      GCS_JSON_KEY_REQUIRED_FIELDS = %w[type project_id private_key client_email].freeze

      belongs_to :organization, class_name: 'Organizations::Organization'
      belongs_to :offline_export, class_name: 'Import::Offline::Export', optional: true
      belongs_to :bulk_import, inverse_of: :offline_configuration, optional: true

      encrypts :object_storage_credentials

      validates :provider, :bucket, :export_prefix, :object_storage_credentials, presence: true
      validates :provider, inclusion: { in: :supported_providers }
      validates :bucket, length: { minimum: 3, maximum: 63 }, format: { with: S3_BUCKET_REGEXP }
      validates :object_storage_credentials, json_schema: {
        filename: 'import_offline_configuration_aws_s3_credentials', size_limit: 64.kilobytes
      }, if: :aws?
      validates :object_storage_credentials, json_schema: {
        filename: 'import_offline_configuration_s3_compatible_credentials', size_limit: 64.kilobytes
      }, if: :s3_compatible?
      validates :object_storage_credentials, json_schema: {
        filename: 'import_offline_configuration_gcs_hmac_credentials', size_limit: 64.kilobytes
      }, if: :gcs_hmac?
      validates :object_storage_credentials, json_schema: {
        filename: 'import_offline_configuration_gcs_credentials', size_limit: 64.kilobytes
      }, if: :gcs?
      validates :endpoint, addressable_url: true, length: { maximum: 255 }, if: :s3_compatible?
      validates :entity_prefix_mapping, json_schema: {
        filename: 'import_offline_configuration_entity_prefix_mapping', size_limit: 64.kilobytes
      }

      validates_with ExactlyOnePresentValidator, fields: [:offline_export, :bulk_import],
        message: ->(_fields) { _('must belong to either an offline export or bulk import') }

      enum :provider, {
        aws: 0,
        s3_compatible: 1,
        gcs_hmac: 2,
        gcs: 3
      }

      after_initialize :generate_export_prefix
      before_validation :flatten_gcs_json_key

      def entity_prefix_for_path(source_full_path)
        entity_prefix_mapping[source_full_path]
      end

      # Returns the immediate descendant subgroups of the given parent path.
      #
      # @param parent_source_full_path [String] the source full path of the parent group (e.g. "group/subgroup")
      # @return [Array<HashWithIndifferentAccess>] hashes with :full_path and :path keys for each subgroup
      def subgroup_paths_for(parent_source_full_path)
        child_paths_for(parent_source_full_path, 'group_')
      end

      # Returns the immediate descendant projects of the given parent path.
      #
      # @param parent_source_full_path [String] the source full path of the parent group (e.g. "group/subgroup")
      # @return [Array<HashWithIndifferentAccess>] hashes with :full_path and :path keys for each project
      def project_paths_for(parent_source_full_path)
        child_paths_for(parent_source_full_path, 'project_')
      end

      def endpoint
        object_storage_credentials.with_indifferent_access[:endpoint] if object_storage_credentials.present?
      end

      private

      def generate_export_prefix
        return if export_prefix.present?

        self.export_prefix = "#{Time.current.strftime('%F_%H-%M-%S')}_export_#{SecureRandom.alphanumeric(8)}"
      end

      # The API accepts the service account key as a pasted JSON string. We parse
      # it here and replace google_json_key_string with the individual key fields
      # fog-google needs (GCS_JSON_KEY_REQUIRED_FIELDS), so the JSON schema can
      # validate each field and we drop everything else the key carries.
      #
      # Keeping only the required fields is the primary SSRF defense (see
      # GCS_JSON_KEY_REQUIRED_FIELDS), so this fails closed: a key that is not
      # valid JSON or not a JSON object is rejected here rather than persisted.
      # The credentials are read by the object storage client immediately after
      # validation (before save), so this must run before validation, not before
      # save.
      def flatten_gcs_json_key
        return unless gcs?
        return unless object_storage_credentials.is_a?(Hash)

        credentials = object_storage_credentials.with_indifferent_access
        raw_key = credentials[:google_json_key_string]
        return unless raw_key.is_a?(String)

        parsed_key = Gitlab::Json::SafeParser.parse(raw_key)

        unless parsed_key.is_a?(Hash)
          errors.add(:base, gcs_json_key_invalid_message)
          throw :abort # rubocop:disable Cop/BanCatchThrow -- ActiveRecord callbacks halt only via throw :abort
        end

        flattened = credentials.except(:google_json_key_string)
          .merge(parsed_key.slice(*GCS_JSON_KEY_REQUIRED_FIELDS))
        self.object_storage_credentials = flattened.to_h
      rescue JSON::ParserError
        errors.add(:base, gcs_json_key_invalid_message)
        throw :abort # rubocop:disable Cop/BanCatchThrow -- ActiveRecord callbacks halt only via throw :abort
      end

      def gcs_json_key_invalid_message
        s_('OfflineTransfer|The Google Cloud service account key must be a valid JSON object.')
      end

      def supported_providers
        providers = self.class.providers

        unless Gitlab::CurrentSettings.allow_s3_compatible_storage_for_offline_transfer?
          providers = providers.except(:s3_compatible)
        end

        providers.keys.map(&:to_s)
      end

      def child_paths_for(parent_source_full_path, entity_type_prefix)
        parent_path_prefix = "#{parent_source_full_path}/"

        entity_prefix_mapping.filter_map do |full_path, entity_prefix|
          next unless full_path.start_with?(parent_path_prefix)
          next unless entity_prefix.start_with?(entity_type_prefix)

          path = full_path.delete_prefix(parent_path_prefix)

          next if path.include?('/')
          next if path.empty?

          { full_path: full_path, path: path }.with_indifferent_access
        end
      end
    end
  end
end
