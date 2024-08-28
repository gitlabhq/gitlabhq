# frozen_string_literal: true

module Import
  module Placeholders
    class Membership < ApplicationRecord
      self.table_name = 'import_placeholder_memberships'

      belongs_to :source_user, class_name: 'Import::SourceUser'
      belongs_to :namespace
      belongs_to :group
      belongs_to :project

      validates :access_level, :namespace_id, :source_user_id, presence: true
      validate :validate_project_or_group_present
      validate :validate_access_level

      private

      def validate_project_or_group_present
        return if group_id.present? ^ project_id.present?

        errors.add(:base, :blank, message: 'one of group_id or project_id must be present')
      end

      def validate_access_level
        return if access_level.in?(member_model.access_level_roles.values)

        errors.add(:access_level, :inclusion)
      end

      def member_model
        return ProjectMember if project_id.present?

        GroupMember
      end
    end
  end
end
