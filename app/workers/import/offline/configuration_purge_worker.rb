# frozen_string_literal: true

module Import
  module Offline
    class ConfigurationPurgeWorker
      include ApplicationWorker

      feature_category :importers
      deduplicate :until_executing
      data_consistency :sticky

      idempotent!

      def perform(configuration_id)
        configuration = ::Import::Offline::Configuration.find_by_id(configuration_id)
        return unless configuration

        configuration.delete
      end
    end
  end
end
