# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class ReplaceBlockedByLinks
      class IssueLink < ActiveRecord::Base
        self.table_name = 'issue_links'
      end

      def perform(start_id, stop_id)
        blocked_by_links = IssueLink.where(id: start_id..stop_id).where(link_type: 2)

        ActiveRecord::Base.transaction do
          # if there is duplicit bi-directional relation (issue2 is blocked by issue1
          # and issue1 already links issue2), then we can just delete 'blocked by'.
          # This should be rare as we have a pre-create check which checks if issues are
          # already linked
          blocked_by_links
            .joins('INNER JOIN issue_links as opposite_links ON issue_links.source_id = opposite_links.target_id AND issue_links.target_id = opposite_links.source_id')
            .where('opposite_links.link_type': 1)
            .delete_all

          blocked_by_links.update_all('source_id=target_id,target_id=source_id,link_type=1')
        end
      end
    end
  end
end
