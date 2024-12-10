# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGroupWikiActivityEvents < BatchedMigrationJob
      operation_name :backfill_group_wiki_activity_events
      scope_to ->(relation) { relation.where(target_type: 'WikiPage::Meta', project_id: nil, group_id: nil) }
      feature_category :wiki

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where('events.target_id = wiki_page_meta.id')
            .update_all('group_id = wiki_page_meta.namespace_id FROM wiki_page_meta')
        end
      end
    end
  end
end
