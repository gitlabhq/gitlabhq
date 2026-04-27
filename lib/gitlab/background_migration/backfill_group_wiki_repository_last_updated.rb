# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGroupWikiRepositoryLastUpdated < BatchedMigrationJob
      operation_name :backfill_group_wiki_repository_last_updated
      feature_category :geo_replication

      class Shard < ApplicationRecord
        self.table_name = 'shards'
      end

      class GroupWikiRepository < ApplicationRecord
        self.table_name = 'group_wiki_repositories'
        self.primary_key = 'group_id'
        belongs_to :shard, class_name: 'BackfillGroupWikiRepositoryLastUpdated::Shard'
        belongs_to :group, class_name: 'BackfillGroupWikiRepositoryLastUpdated::Group'
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch = GroupWikiRepository.where(group_id: sub_batch, last_repository_updated_at: nil)
            .includes(:shard)

          updates = []

          sub_batch.each do |record|
            commit = fetch_commit(record)

            next unless commit

            updates << {
              group_id: record.group_id, shard_id: record.shard_id,
              disk_path: record.disk_path, last_repository_updated_at: commit.committed_date
            }
          end

          if updates.any?
            GroupWikiRepository.upsert_all(updates, unique_by: :group_id, update_only: [:last_repository_updated_at])
          end
        end
      end

      private

      def fetch_commit(record)
        raw_repo = Gitlab::Git::Repository.new(
          record.shard.name,
          "#{record.disk_path}.wiki.git",
          nil, nil
        )

        raw_repo.commit
      rescue RuntimeError => re # rubocop:disable BackgroundMigration/AvoidSilentRescueExceptions -- We do log a warning
        raise unless re.message.include?("storage not found")

        Gitlab::AppLogger.warn(
          message: "group: #{record.group_id} -- #{re.message}",
          class: self.class.name
        )
        nil
      end
    end
  end
end
