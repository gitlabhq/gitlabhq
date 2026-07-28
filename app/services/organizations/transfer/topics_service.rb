# frozen_string_literal: true

module Organizations
  module Transfer
    class TopicsService
      include Gitlab::Utils::StrongMemoize

      def initialize(group:, old_organization:, new_organization:)
        @group = group
        @old_organization = old_organization
        @new_organization = new_organization
      end

      def execute
        counter_deltas = Hash.new { |h, k| h[k] = { total: 0, non_private: 0 } }

        old_topics.find_each do |old_topic|
          new_topic = find_or_create_in_new_organization(old_topic)
          next if new_topic.id == old_topic.id

          repoint_and_accumulate_deltas(old_topic, new_topic, counter_deltas)
        end

        flush_counter_deltas(counter_deltas)
      end

      private

      attr_reader :group, :old_organization, :new_organization

      # rubocop:disable CodeReuse/ActiveRecord -- scoped queries for topic transfer
      def projects
        Project.in_namespace(group.self_and_descendant_ids(skope: Namespace))
      end
      strong_memoize_attr :projects

      def old_topics
        project_topics = Projects::ProjectTopic.joins(project: :namespace)
          .where("project_topics.topic_id = topics.id")
          .where("namespaces.traversal_ids @> ARRAY[?]::bigint[]", group.id)

        Projects::Topic
          .where(organization_id: old_organization.id)
          .where_exists(project_topics)
      end

      # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- safe_find_or_create_by requires subtransaction for atomicity
      def find_or_create_in_new_organization(old_topic)
        Projects::Topic.safe_find_or_create_by!(
          organization_id: new_organization.id,
          name: old_topic.name
        ) do |topic|
          topic.title = old_topic.title.presence || old_topic.name
          topic.description = old_topic.description
          topic.slug = Gitlab::Slug::Path.new(old_topic.name).generate
        end
      end
      # rubocop:enable Performance/ActiveRecordSubtransactionMethods

      def repoint_and_accumulate_deltas(old_topic, new_topic, counter_deltas)
        scoped_project_topics = Projects::ProjectTopic
          .where(topic_id: old_topic.id, project_id: projects)

        already_assigned = Projects::ProjectTopic
          .from('project_topics AS pt_dup')
          .where(pt_dup: { topic_id: new_topic.id })
          .where('pt_dup.project_id = project_topics.project_id')

        non_private_count = non_private_project_count(old_topic)

        duplicates_deleted = scoped_project_topics.where_exists(already_assigned).delete_all
        moved_count = scoped_project_topics.update_all(topic_id: new_topic.id)

        total_removed = moved_count + duplicates_deleted
        counter_deltas[old_topic.id][:total] -= total_removed
        counter_deltas[old_topic.id][:non_private] -= non_private_count
        counter_deltas[new_topic.id][:total] += moved_count
        counter_deltas[new_topic.id][:non_private] += non_private_count
      end

      def non_private_project_count(topic)
        project_topics = Projects::ProjectTopic
            .where('project_topics.project_id = projects.id')
            .where(topic_id: topic.id)

        projects
          .where(visibility_level: [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC])
          .where_exists(project_topics)
          .count
      end

      def flush_counter_deltas(counter_deltas)
        counter_deltas.each do |topic_id, deltas|
          next if deltas[:total] == 0 && deltas[:non_private] == 0

          Projects::Topic.where(id: topic_id).update_counters(
            total_projects_count: deltas[:total],
            non_private_projects_count: deltas[:non_private]
          )
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end
