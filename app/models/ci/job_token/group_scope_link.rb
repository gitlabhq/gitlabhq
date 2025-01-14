# frozen_string_literal: true

# The connection between a source group (which the job token scope's allowlist applies too)
# and a target project which is added to the scope's allowlist.

module Ci
  module JobToken
    class GroupScopeLink < Ci::ApplicationRecord
      include BulkInsertSafe

      self.table_name = 'ci_job_token_group_scope_links'

      GROUP_LINK_LIMIT = 200

      belongs_to :source_project, class_name: 'Project'
      # the group added to the scope's allowlist
      belongs_to :target_group, class_name: '::Group'
      belongs_to :added_by, class_name: 'User'

      validates :job_token_policies, json_schema: { filename: 'ci_job_token_policies' }, allow_blank: true

      scope :with_source, ->(project) { where(source_project: project) }
      scope :with_target, ->(group) { where(target_group: group) }
      scope :autopopulated, -> { where(autopopulated: true) }

      validates :source_project, presence: true
      validates :target_group, presence: true
      validate :source_project_under_link_limit, on: :create

      def self.for_source_and_target(source_project, target_group)
        find_by(source_project: source_project, target_group: target_group)
      end

      private

      def source_project_under_link_limit
        return unless source_project

        existing_links_count = self.class.with_source(source_project).count

        return if existing_links_count < GROUP_LINK_LIMIT

        errors.add(:source_project, "exceeds the allowable number of group links")
      end
    end
  end
end
