# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class ReindexAction < ActiveRecord::Base
        self.table_name = 'postgres_reindex_actions'

        enum state: { started: 0, finished: 1, failed: 2 }

        def self.keep_track_of(index, &block)
          action = create!(
            index_identifier: index.identifier,
            action_start: Time.zone.now,
            ondisk_size_bytes_start: index.ondisk_size_bytes
          )

          yield

          action.state = :finished
        rescue
          action.state = :failed
          raise
        ensure
          index.reload # rubocop:disable Cop/ActiveRecordAssociationReload

          action.action_end = Time.zone.now
          action.ondisk_size_bytes_end = index.ondisk_size_bytes

          action.save!
        end
      end
    end
  end
end
