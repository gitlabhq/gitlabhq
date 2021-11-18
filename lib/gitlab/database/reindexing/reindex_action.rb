# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class ReindexAction < SharedModel
        self.table_name = 'postgres_reindex_actions'

        belongs_to :index, foreign_key: :index_identifier, class_name: 'Gitlab::Database::PostgresIndex'
        enum state: { started: 0, finished: 1, failed: 2 }

        # Amount of time to consider a previous reindexing *recent*
        RECENT_THRESHOLD = 10.days

        scope :recent, -> { where(state: :finished).where('action_end > ?', Time.zone.now - RECENT_THRESHOLD) }

        def self.create_for(index)
          create!(
            index_identifier: index.identifier,
            action_start: Time.zone.now,
            ondisk_size_bytes_start: index.ondisk_size_bytes,
            bloat_estimate_bytes_start: index.bloat_size
          )
        end

        def finish
          index.reload # rubocop:disable Cop/ActiveRecordAssociationReload

          self.state = :finished unless failed?
          self.action_end = Time.zone.now
          self.ondisk_size_bytes_end = index.ondisk_size_bytes

          save!
        end
      end
    end
  end
end
