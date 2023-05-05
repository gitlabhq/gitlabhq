# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The class to merge project topics with the same case insensitive name
    class MergeTopicsWithSameName
      # Temporary AR model for topics
      class Topic < ActiveRecord::Base
        self.table_name = 'topics'
      end

      # Temporary AR model for project topic assignment
      class ProjectTopic < ActiveRecord::Base
        self.table_name = 'project_topics'
      end

      def perform(topic_names)
        topic_names.each do |topic_name|
          topics = Topic.where('LOWER(name) = ?', topic_name)
            .order(total_projects_count: :desc, non_private_projects_count: :desc, id: :asc)
            .to_a
          topic_to_keep = topics.shift
          merge_topics(topic_to_keep, topics) if topics.any?
        end
      end

      private

      def merge_topics(topic_to_keep, topics_to_remove)
        description = topic_to_keep.description

        topics_to_remove.each do |topic|
          description ||= topic.description if topic.description.present?
          process_avatar(topic_to_keep, topic) if topic.avatar.present?

          ProjectTopic.transaction do
            ProjectTopic.where(topic_id: topic.id)
              .where.not(project_id: ProjectTopic.where(topic_id: topic_to_keep).select(:project_id))
              .update_all(topic_id: topic_to_keep.id)
            ProjectTopic.where(topic_id: topic.id).delete_all
          end
        end

        Topic.where(id: topics_to_remove).delete_all

        topic_to_keep.update(
          description: description,
          total_projects_count: total_projects_count(topic_to_keep.id),
          non_private_projects_count: non_private_projects_count(topic_to_keep.id)
        )
      end

      # We intentionally use application code here because we need to copy/remove avatar files
      def process_avatar(topic_to_keep, topic_to_remove)
        topic_to_remove = ::Projects::Topic.find(topic_to_remove.id)
        topic_to_keep = ::Projects::Topic.find(topic_to_keep.id)
        unless topic_to_keep.avatar.present?
          topic_to_keep.avatar = topic_to_remove.avatar
          topic_to_keep.save!
        end

        topic_to_remove.remove_avatar!
        topic_to_remove.save!
      end

      def total_projects_count(topic_id)
        ProjectTopic.where(topic_id: topic_id).count
      end

      def non_private_projects_count(topic_id)
        ProjectTopic.joins('INNER JOIN projects ON project_topics.project_id = projects.id')
            .where(project_topics: { topic_id: topic_id }).where('projects.visibility_level in (10, 20)').count
      end
    end
  end
end
