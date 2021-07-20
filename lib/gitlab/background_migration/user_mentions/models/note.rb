# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class Note < ActiveRecord::Base
          include EachBatch
          include Concerns::IsolatedMentionable
          include CacheMarkdownField

          self.table_name = 'notes'
          self.inheritance_column = :_type_disabled

          attr_mentionable :note, pipeline: :note
          cache_markdown_field :note, pipeline: :note, issuable_state_filter_enabled: true

          belongs_to :author, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::User"
          belongs_to :noteable, polymorphic: true
          belongs_to :project, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::Project"

          def for_personal_snippet?
            noteable && noteable.instance_of?(PersonalSnippet)
          end

          def for_project_noteable?
            !for_personal_snippet? && !for_epic?
          end

          def skip_project_check?
            !for_project_noteable?
          end

          def for_epic?
            noteable && noteable_type == 'Epic'
          end

          def user_mention_resource_id
            noteable_id || commit_id
          end

          def user_mention_note_id
            id
          end

          def noteable
            super unless for_commit?
          end

          def for_commit?
            noteable_type == "Commit"
          end

          private

          def mentionable_params
            return super unless for_epic?

            super.merge(banzai_context_params)
          end

          def banzai_context_params
            return {} unless noteable

            { group: noteable.group, label_url_method: :group_epics_url }
          end
        end
      end
    end
  end
end
