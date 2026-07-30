# frozen_string_literal: true

module Organizations
  class TransferTopicAvatarWorker
    include ApplicationWorker

    data_consistency :sticky
    idempotent!

    feature_category :organization
    urgency :low

    defer_on_database_health_signal :gitlab_main, [:topics], 1.minute

    def perform(source_topic_id, target_topic_id)
      source_topic = Projects::Topic.find_by_id(source_topic_id)
      return unless source_topic

      target_topic = Projects::Topic.find_by_id(target_topic_id)
      return unless target_topic
      return if target_topic.avatar.present?
      return unless source_topic.avatar.present?

      target_topic.avatar = source_topic.avatar.file
      target_topic.save!
    end
  end
end
