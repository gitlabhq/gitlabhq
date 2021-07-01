# frozen_string_literal: true

# The connection between a source project (which defines the job token scope)
# and a target project which is the one allowed to be accessed by the job token.

module Ci
  module JobToken
    class ProjectScopeLink < ApplicationRecord
      self.table_name = 'ci_job_token_project_scope_links'

      belongs_to :source_project, class_name: 'Project'
      belongs_to :target_project, class_name: 'Project'
      belongs_to :added_by, class_name: 'User'

      scope :from_project, ->(project) { where(source_project: project) }
      scope :to_project, ->(project) { where(target_project: project) }

      validates :source_project, presence: true
      validates :target_project, presence: true
      validate :not_self_referential_link

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
