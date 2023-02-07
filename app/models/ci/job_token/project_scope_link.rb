# frozen_string_literal: true

# The connection between a source project (which the job token scope's allowlist applies too)
# and a target project which is added to the scope's allowlist.

module Ci
  module JobToken
    class ProjectScopeLink < Ci::ApplicationRecord
      self.table_name = 'ci_job_token_project_scope_links'

      belongs_to :source_project, class_name: 'Project'
      # the project added to the scope's allowlist
      belongs_to :target_project, class_name: 'Project'
      belongs_to :added_by, class_name: 'User'

      scope :with_access_direction, ->(direction) { where(direction: direction) }
      scope :with_source, ->(project)   { where(source_project: project) }
      scope :with_target, ->(project)   { where(target_project: project) }

      validates :source_project, presence: true
      validates :target_project, presence: true
      validate :not_self_referential_link

      # When outbound the target project is allowed to be accessed by the source job token.
      # When inbound the source project is allowed to be accessed by the target job token.
      enum direction: {
        outbound: 0,
        inbound: 1
      }

      def self.for_source_and_target(source_project, target_project)
        self.find_by(source_project: source_project, target_project: target_project)
      end

      private

      def not_self_referential_link
        return unless source_project && target_project

        if source_project == target_project
          self.errors.add(:target_project, _("can't be the same as the source project"))
        end
      end
    end
  end
end
