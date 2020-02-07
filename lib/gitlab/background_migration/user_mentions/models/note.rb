# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class Note < ActiveRecord::Base
          include IsolatedMentionable
          include CacheMarkdownField

          self.table_name = 'notes'
          self.inheritance_column = :_type_disabled

          attr_mentionable :note, pipeline: :note
          cache_markdown_field :note, pipeline: :note, issuable_state_filter_enabled: true

          belongs_to :author, class_name: "User"
          belongs_to :noteable, polymorphic: true
          belongs_to :project

          def for_personal_snippet?
            noteable.class.name == 'PersonalSnippet'
          end

          def for_project_noteable?
            !for_personal_snippet?
          end

          def skip_project_check?
            !for_project_noteable?
          end

          def for_epic?
            noteable.class.name == 'Epic'
          end

          def user_mention_resource_id
            noteable_id || commit_id
          end

          def user_mention_note_id
            id
          end

          private

          def mentionable_params
            return super unless for_epic?

            super.merge(banzai_context_params)
          end

          def banzai_context_params
            { group: noteable.group, label_url_method: :group_epics_url }
          end
        end
      end
    end
  end
end
