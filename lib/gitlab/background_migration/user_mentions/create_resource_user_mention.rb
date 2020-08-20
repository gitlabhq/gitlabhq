# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      class CreateResourceUserMention
        # Resources that have mentions to be migrated:
        # issue, merge_request, epic, commit, snippet, design

        BULK_INSERT_SIZE = 1_000
        ISOLATION_MODULE = 'Gitlab::BackgroundMigration::UserMentions::Models'

        def perform(resource_model, join, conditions, with_notes, start_id, end_id)
          return unless Feature.enabled?(:migrate_user_mentions, default_enabled: true)

          resource_model = "#{ISOLATION_MODULE}::#{resource_model}".constantize if resource_model.is_a?(String)
          model = with_notes ? Gitlab::BackgroundMigration::UserMentions::Models::Note : resource_model
          resource_user_mention_model = resource_model.user_mention_model

          records = model.joins(join).where(conditions).where(id: start_id..end_id)

          records.each_batch(of: BULK_INSERT_SIZE) do |records|
            mentions = []
            records.each do |record|
              mention_record = record.build_mention_values(resource_user_mention_model.resource_foreign_key)
              mentions << mention_record unless mention_record.blank?
            end

            resource_user_mention_model.insert_all(mentions) unless mentions.empty?
          end
        end
      end
    end
  end
end
