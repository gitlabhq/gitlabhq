# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The class to extract the project topics into a separate `topics` table
    class ExtractProjectTopicsIntoSeparateTable
      # Temporary AR table for tags
      class Tag < ActiveRecord::Base
        self.table_name = 'tags'
      end

      # Temporary AR table for taggings
      class Tagging < ActiveRecord::Base
        self.table_name = 'taggings'
        belongs_to :tag
      end

      # Temporary AR table for topics
      class Topic < ActiveRecord::Base
        self.table_name = 'topics'
      end

      # Temporary AR table for project topics
      class ProjectTopic < ActiveRecord::Base
        self.table_name = 'project_topics'
        belongs_to :topic
      end

      def perform(start_id, stop_id)
        Tagging.includes(:tag).where(taggable_type: 'Project', id: start_id..stop_id).each do |tagging|
          topic = Topic.find_or_create_by(name: tagging.tag.name)
          project_topic = ProjectTopic.find_or_create_by(project_id: tagging.taggable_id, topic: topic)

          tagging.delete if project_topic.persisted?
        end

        mark_job_as_succeeded(start_id, stop_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
