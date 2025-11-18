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

        configuration.update!(access_token: nil)
      end
    end
  end
end
