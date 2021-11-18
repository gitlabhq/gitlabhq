# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class QueuedAction < SharedModel
        self.table_name = 'postgres_reindex_queued_actions'

        enum state: { queued: 0, done: 1, failed: 2 }

        belongs_to :index, foreign_key: :index_identifier, class_name: 'Gitlab::Database::PostgresIndex'

        scope :in_queue_order, -> { queued.order(:created_at) }

        def to_s
          "queued action [ id = #{id}, index: #{index_identifier} ]"
        end
      end
    end
  end
end
