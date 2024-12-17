# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGroupWikiRepositoryStatesGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_group_wiki_repository_states_group_id
      feature_category :geo_replication

      # override as parent table primary key is group_id
      def backfill_via_table_primary_key
        'group_id'
      end
    end
  end
end
