# frozen_string_literal: true

module Import
  module BulkImports
    class ConfigurationPurgeWorker
      include ApplicationWorker

      feature_category :importers
      deduplicate :until_executing
      data_consistency :sticky

      idempotent!

      def perform(id)
        configuration = ::BulkImports::Configuration.find_by_id(id)

        return unless configuration

        begin
          configuration.destroy!
        rescue ActiveRecord::RecordNotDestroyed => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
            e,
            {
              message: "Failed to purge bulk import configuration due to errors"
            }.merge(logger.default_attributes)
          )
        end
      end
    end
  end
end
