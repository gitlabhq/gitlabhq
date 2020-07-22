# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        module DesignManagement
          class Design < ActiveRecord::Base
            include EachBatch
            include Concerns::MentionableMigrationMethods

            def self.user_mention_model
              Gitlab::BackgroundMigration::UserMentions::Models::DesignUserMention
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
          end
        end
      end
    end
  end
end
