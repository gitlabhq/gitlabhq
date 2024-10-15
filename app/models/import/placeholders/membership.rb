# frozen_string_literal: true

module Import
  module Placeholders
    class Membership < ApplicationRecord
      include EachBatch

      self.table_name = 'import_placeholder_memberships'

      belongs_to :source_user, class_name: 'Import::SourceUser'
      belongs_to :namespace
      belongs_to :group
      belongs_to :project

      validates :access_level, :namespace_id, :source_user_id, presence: true
      validates :access_level, inclusion: { in: Gitlab::Access.all_values }
      validates :group_id, uniqueness: { scope: [:source_user_id] }, allow_nil: true
      validates :project_id, uniqueness: { scope: [:source_user_id] }, allow_nil: true
      validate :validate_project_or_group_present

      scope :with_projects, -> { includes(:project) }
      scope :with_groups, -> { includes(:group) }
      scope :by_source_user, ->(source_users) { where(source_user: source_users) }
      scope :by_group, ->(groups) { where(group: groups) }
      scope :by_project, ->(projects) { where(project: projects) }

      private

      def validate_project_or_group_present
        return if group_id.present? ^ project_id.present?

        errors.add(:base, :blank, message: 'one of group_id or project_id must be present')
      end
    end
  end
end
