# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class Epic < ActiveRecord::Base
          include EachBatch
          include Concerns::IsolatedMentionable
          include Concerns::MentionableMigrationMethods
          include CacheMarkdownField

          attr_mentionable :title, pipeline: :single_line
          attr_mentionable :description
          cache_markdown_field :title, pipeline: :single_line
          cache_markdown_field :description, issuable_state_filter_enabled: true

          self.table_name = 'epics'
          self.inheritance_column = :_type_disabled

          belongs_to :author, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::User"
          belongs_to :group, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::Group"

          def self.user_mention_model
            Gitlab::BackgroundMigration::UserMentions::Models::EpicUserMention
          end

          def user_mention_model
            self.class.user_mention_model
          end

          def project
            nil
          end

          def mentionable_params
            { group: group, label_url_method: :group_epics_url }
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
