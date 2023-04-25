# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class creates/updates those namespace statistics
    # that haven't been created nor initialized.
    # It also updates the related namespace statistics
    class PopulateNamespaceStatistics
      def perform(group_ids, statistics)
        # Updating group statistics might involve calling Gitaly.
        # For example, when calculating `wiki_size`, we will need
        # to perform the request to check if the repo exists and
        # also the repository size.
        #
        # The `allow_n_plus_1_calls` method is only intended for
        # dev and test. It won't be raised in prod.
        ::Gitlab::GitalyClient.allow_n_plus_1_calls do
          relation(group_ids).each do |group|
            upsert_namespace_statistics(group, statistics)
          end
        end
      end

      private

      def upsert_namespace_statistics(group, statistics)
        response = ::Groups::UpdateStatisticsService.new(group, statistics: statistics).execute

        error_message("#{response.message} group: #{group.id}") if response.error?
      end

      def logger
        @logger ||= ::Gitlab::BackgroundMigration::Logger.build
      end

      def error_message(message)
        logger.error(message: "Namespace Statistics Migration: #{message}")
      end

      def relation(group_ids)
        Group.includes(:namespace_statistics).where(id: group_ids)
      end
    end
  end
end

Gitlab::BackgroundMigration::PopulateNamespaceStatistics.prepend_mod_with('Gitlab::BackgroundMigration::PopulateNamespaceStatistics')
