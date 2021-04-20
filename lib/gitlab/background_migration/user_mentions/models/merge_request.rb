# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class MergeRequest < ActiveRecord::Base
          include EachBatch
          include Concerns::IsolatedMentionable
          include CacheMarkdownField
          include Concerns::MentionableMigrationMethods

          attr_mentionable :title, pipeline: :single_line
          attr_mentionable :description
          cache_markdown_field :title, pipeline: :single_line
          cache_markdown_field :description, issuable_state_filter_enabled: true

          self.table_name = 'merge_requests'
          self.inheritance_column = :_type_disabled

          belongs_to :author, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::User"
          belongs_to :target_project, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::Project"
          belongs_to :source_project, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::Project"

          alias_attribute :project, :target_project

          def self.user_mention_model
            Gitlab::BackgroundMigration::UserMentions::Models::MergeRequestUserMention
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
