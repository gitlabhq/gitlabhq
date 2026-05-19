# frozen_string_literal: true

module Import
  module Offline
    class ExportStatus < ::Import::ExportStatus
      OFFLINE_CACHE_KEY = 'offline_import/export_status/%{entity_id}/%{relation}'

      def initialize(pipeline_tracker, relation)
        super

        @configuration = @entity.bulk_import.offline_configuration

        @client = ::Import::Clients::ObjectStorage.new(
          provider: @configuration.provider,
          bucket: @configuration.bucket,
          credentials: @configuration.object_storage_credentials
        )
      end

      def in_progress?
        false
      end

      def failed?
        status['error'].present?
      end

      # In offline transfer, relation exports are never pending. All export files must have already completed
      # and been uploaded to the configured bucket. Missing files are considered failed.
      def waiting_on_export?
        false
      end

      def error
        status['error']
      end

      def batched?
        !!status['batched']
      end

      def batches_count
        return 0 unless batched?

        status['batch_numbers'].length
      end

      def all_batch_numbers
        status['batch_numbers'].map(&:to_i).sort
      end

      def batch_failed?(batch_number)
        raise ArgumentError, "Batch number (#{batch_number}) must be >= 1" if batch_number < 1

        return unless batched?

        status['batch_numbers'].map(&:to_i).exclude?(batch_number)
      end

      def batch_error(batch_number)
        return unless batch_failed?(batch_number)

        format(
          s_('OfflineTransfer|Export relation batch file not found for relation: %{relation}, batch: %{batch_number}'),
          relation: relation, batch_number: batch_number
        )
      end

      def total_objects_count
        # TODO: Not yet implemented. See https://gitlab.com/gitlab-org/gitlab/-/work_items/597294
        0
      end

      private

      attr_reader :client, :configuration

      def status
        cached_status = status_from_cache
        return cached_status if cached_status

        status_from_bucket
      end
      strong_memoize_attr :status

      def status_from_bucket
        status = {}

        if batch_numbers.present?
          status['batched'] = true
          status['batch_numbers'] = batch_numbers
        elsif unbatched_relation_key_present?
          status['batched'] = false
          status['batch_numbers'] = []
        else
          status['error'] = format(
            s_('OfflineTransfer|Export files not found for relation: %{relation}'),
            relation: relation
          )
        end

        Gitlab::Json.safe_parse(cache_status(status))
      end

      def batch_keys
        entity_prefix = configuration.entity_prefix_for_path(entity.source_full_path)
        batch_prefix = object_key_builder.batched_object_key_prefix(
          relation: relation, entity_prefix: entity_prefix
        )

        validate_request_url!(batch_prefix)

        client.object_keys_for_prefix(batch_prefix)
      end
      strong_memoize_attr :batch_keys

      def batch_numbers
        batch_keys.filter_map do |key|
          batch_number = object_key_builder.batch_number(key)
          next batch_number if batch_number
        end
      end
      strong_memoize_attr :batch_numbers

      def unbatched_relation_key_present?
        batch_keys.any? { |key| object_key_builder.unbatched_relation_key?(key, relation) }
      end

      def validate_request_url!(prefix)
        url = client.request_url(prefix)
        ::Gitlab::HTTP_V2::UrlBlocker.validate!(url, **Import::Framework::UrlBlockerParams.new.to_h)
      end

      def object_key_builder
        Import::Offline::ObjectKeyBuilder.new(configuration)
      end
      strong_memoize_attr :object_key_builder

      def cache_key(cache_key_template = OFFLINE_CACHE_KEY)
        super
      end
    end
  end
end
