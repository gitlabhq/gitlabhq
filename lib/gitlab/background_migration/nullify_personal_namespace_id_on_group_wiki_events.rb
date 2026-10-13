# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Cleans up events rows where both `group_id` and `personal_namespace_id` are set
    # for `target_type = 'WikiPage::Meta'`.
    #
    # These rows were created during a bug window (GitLab 17.5-17.6, Oct-Nov 2024)
    # where group-wiki events were incorrectly stored with `personal_namespace_id`
    # instead of `group_id`. A December 2024 backfill (BackfillGroupWikiActivityEvents)
    # later set `group_id` on those rows but did not clear `personal_namespace_id`,
    # leaving both columns populated.
    #
    # This migration nullifies `personal_namespace_id` on those rows so that each
    # event has exactly one sharding key set.
    class NullifyPersonalNamespaceIdOnGroupWikiEvents < BatchedMigrationJob
      operation_name :nullify_personal_namespace_id_on_group_wiki_events
      feature_category :wiki

      # rubocop:disable Database/AvoidScopeTo -- supporting indexes: index_events_on_group_id_and_id ON events USING btree (group_id, id) WHERE (group_id IS NOT NULL) and index_events_on_personal_namespace_id ON events USING btree (personal_namespace_id) WHERE (personal_namespace_id IS NOT NULL)
      scope_to ->(relation) do
        relation
          .where(target_type: 'WikiPage::Meta')
          .where.not(group_id: nil)
          .where.not(personal_namespace_id: nil)
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(personal_namespace_id: nil)
        end
      end
      # rubocop:enable Database/AvoidScopeTo
    end
  end
end
