# frozen_string_literal: true

module Topics
  class MergeService
    attr_accessor :source_topic, :target_topic

    def initialize(source_topic, target_topic)
      @source_topic = source_topic
      @target_topic = target_topic
    end

    def execute
      validate_parameters!

      ::Projects::ProjectTopic.transaction do
        move_project_topics
        refresh_target_topic_counters
        delete_source_topic
      end

      ServiceResponse.success
    rescue ArgumentError => e
      ServiceResponse.error(message: e.message)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, source_topic_id: source_topic.id, target_topic_id: target_topic.id)
      ServiceResponse.error(message: _('Topics could not be merged!'))
    end

    private

    def validate_parameters!
      raise ArgumentError, _('The source topic is not a topic.') unless source_topic.is_a?(Projects::Topic)
      raise ArgumentError, _('The target topic is not a topic.') unless target_topic.is_a?(Projects::Topic)

      if source_topic.organization_id != target_topic.organization_id
        raise ArgumentError, _('The source topic and the target topic must belong to the same organization.')
      end

      raise ArgumentError, _('The source topic and the target topic are identical.') if source_topic == target_topic
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def move_project_topics
      project_ids_for_projects_currently_using_source_and_target = ::Projects::ProjectTopic
        .where(topic_id: target_topic).select(:project_id)
      # Only update for projects that exclusively use the source topic
      ::Projects::ProjectTopic.where(topic_id: source_topic.id)
        .where.not(project_id: project_ids_for_projects_currently_using_source_and_target)
        .update_all(topic_id: target_topic.id)

      # Delete source topic for projects that were using source and target
      ::Projects::ProjectTopic.where(topic_id: source_topic.id).delete_all
    end

    def refresh_target_topic_counters
      target_topic.update!(
        total_projects_count: total_projects_count(target_topic.id),
        non_private_projects_count: non_private_projects_count(target_topic.id)
      )
    end

    def delete_source_topic
      source_topic.destroy!
    end

    def total_projects_count(topic_id)
      ::Projects::ProjectTopic.where(topic_id: topic_id).count
    end

    def non_private_projects_count(topic_id)
      ::Projects::ProjectTopic.joins(:project).where(topic_id: topic_id).where('projects.visibility_level in (10, 20)')
        .count
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
