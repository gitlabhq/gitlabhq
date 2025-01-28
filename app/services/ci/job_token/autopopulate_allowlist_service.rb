# frozen_string_literal: true

module Ci
  module JobToken
    class AutopopulateAllowlistService
      include ::Gitlab::Loggable
      include ::Gitlab::Utils::StrongMemoize

      COMPACTION_LIMIT = Ci::JobToken::ProjectScopeLink::PROJECT_LINK_DIRECTIONAL_LIMIT

      def initialize(project, user)
        @project = project
        @user = user
      end

      def execute
        raise Gitlab::Access::AccessDeniedError unless authorized?

        allowlist = Ci::JobToken::Allowlist.new(@project)
        groups = compactor.allowlist_groups
        projects = compactor.allowlist_projects

        ApplicationRecord.transaction do
          allowlist.bulk_add_groups!(groups, user: @user, autopopulated: true)
          allowlist.bulk_add_projects!(projects, user: @user, autopopulated: true)
        end

        ServiceResponse.success
      rescue Gitlab::Utils::TraversalIdCompactor::CompactionLimitCannotBeAchievedError,
        Gitlab::Utils::TraversalIdCompactor::RedundantCompactionEntry,
        Gitlab::Utils::TraversalIdCompactor::UnexpectedCompactionEntry,
        Ci::JobToken::AuthorizationsCompactor::UnexpectedCompactionEntry,
        Ci::JobToken::AuthorizationsCompactor::RedundantCompactionEntry => e
        Gitlab::ErrorTracking.log_exception(e, { project_id: @project.id, user_id: @user.id })
        ServiceResponse.error(message: e.message)
      end

      private

      def compactor
        Ci::JobToken::AuthorizationsCompactor.new(@project.id).tap do |compactor|
          compactor.compact(COMPACTION_LIMIT)
        end
      end
      strong_memoize_attr :compactor

      def authorized?
        @user.can?(:admin_project, @project)
      end
    end
  end
end
