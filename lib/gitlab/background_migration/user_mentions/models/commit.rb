# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class Commit
          include EachBatch
          include Concerns::IsolatedMentionable
          include Concerns::MentionableMigrationMethods

          def self.user_mention_model
            Gitlab::BackgroundMigration::UserMentions::Models::CommitUserMention
          end

          def user_mention_model
            self.class.user_mention_model
          end

          def user_mention_resource_id
            id
          end

          def user_mention_note_id
            'NULL'
          end

          def self.no_quote_columns
            [:note_id]
          end
        end
      end
    end
  end
end
