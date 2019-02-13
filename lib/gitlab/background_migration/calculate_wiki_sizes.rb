# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class CalculateWikiSizes
      def perform(start_id, stop_id)
        ::ProjectStatistics.where(wiki_size: nil)
          .where(id: start_id..stop_id)
          .includes(project: [:route, :group, namespace: [:owner]]).find_each do |statistics|
          statistics.refresh!(only: [:wiki_size])
        rescue => e
          Rails.logger.error "Failed to update wiki statistics. id: #{statistics.id} message: #{e.message}"
        end
      end
    end
  end
end
