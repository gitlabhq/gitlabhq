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
          resource_model = "#{ISOLATION_MODULE}::#{resource_model}".constantize if resource_model.is_a?(String)
          model = with_notes ? Gitlab::BackgroundMigration::UserMentions::Models::Note : resource_model
          resource_user_mention_model = resource_model.user_mention_model

          records = model.joins(join).where(conditions).where(id: start_id..end_id)

          records.in_groups_of(BULK_INSERT_SIZE, false).each do |records|
            mentions = []
            records.each do |record|
              mention_record = record.build_mention_values(resource_user_mention_model.resource_foreign_key)
              mentions << mention_record unless mention_record.blank?
            end

            Gitlab::Database.bulk_insert( # rubocop:disable Gitlab/BulkInsert
              resource_user_mention_model.table_name,
              mentions,
              return_ids: true,
              disable_quote: resource_model.no_quote_columns,
              on_conflict: :do_nothing
            )
          end
        end
      end
    end
  end
end
