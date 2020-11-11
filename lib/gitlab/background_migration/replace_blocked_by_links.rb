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
          # There could be two edge cases:
          # 1) issue1 is blocked by issue2 AND issue2 blocks issue1 (type 1)
          # 2) issue1 is blocked by issue2 AND issue2 is related to issue1 (type 0)
          # In both cases cases we couldn't convert blocked by relation to
          # `issue2 blocks issue` because there is already a link with the same
          # source/target id. To avoid these conflicts, we first delete any
          # "opposite" links before we update `blocked by` relation.  This
          # should be rare as we have a pre-create check which checks if issues
          # are already linked
          opposite_ids = blocked_by_links
            .select('opposite_links.id')
            .joins('INNER JOIN issue_links as opposite_links ON issue_links.source_id = opposite_links.target_id AND issue_links.target_id = opposite_links.source_id')
          IssueLink.where(id: opposite_ids).delete_all

          blocked_by_links.update_all('source_id=target_id,target_id=source_id,link_type=1')
        end
      end
    end
  end
end
