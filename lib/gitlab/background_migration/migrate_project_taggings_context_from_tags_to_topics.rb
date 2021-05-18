# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The class to migrate the context of project taggings from `tags` to `topics`
    class MigrateProjectTaggingsContextFromTagsToTopics
      # Temporary AR table for taggings
      class Tagging < ActiveRecord::Base
        include EachBatch

        self.table_name = 'taggings'
      end

      def perform(start_id, stop_id)
        Tagging.where(taggable_type: 'Project', context: 'tags', id: start_id..stop_id).each_batch(of: 500) do |relation|
          relation.update_all(context: 'topics')
        end
      end
    end
  end
end
