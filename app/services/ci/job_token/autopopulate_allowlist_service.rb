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

      def unsafe_execute!
        allowlist = Ci::JobToken::Allowlist.new(@project)
        groups = compactor.allowlist_groups
        projects = compactor.allowlist_projects

        ApplicationRecord.transaction do
          allowlist.bulk_add_groups!(groups, user: @user, autopopulated: true) if groups.any?
          allowlist.bulk_add_projects!(projects, user: @user, autopopulated: true) if projects.any?
        end

        enable_enforcement!

        ServiceResponse.success
      rescue Ci::JobToken::AuthorizationsCompactor::Error => e
        Gitlab::ErrorTracking.log_exception(e, { project_id: @project.id, user_id: @user.id })
        ServiceResponse.error(message: e.message)
      end

      def execute
        raise Gitlab::Access::AccessDeniedError unless authorized?

        unsafe_execute!
      end

      private

      def compactor
        Ci::JobToken::AuthorizationsCompactor.new(@project).tap do |compactor|
          compactor.compact(COMPACTION_LIMIT)
        end
      end
      strong_memoize_attr :compactor

      def authorized?
        @user.can?(:admin_project, @project)
      end

      def enable_enforcement!
        @project.ci_cd_settings.update!(inbound_job_token_scope_enabled: true)
      end
    end
  end
end
