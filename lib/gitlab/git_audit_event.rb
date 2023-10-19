# frozen_string_literal: true

module Gitlab
  class GitAuditEvent # rubocop:disable Gitlab/NamespacedClass
    attr_reader :project, :user, :author

    def initialize(player, project)
      @project = project
      @author = player.is_a?(::API::Support::GitAccessActor) ? player.deploy_key_or_user : player
      @user = player.is_a?(::API::Support::GitAccessActor) ? player.user : player
    end

    def send_audit_event(msg)
      return if user.blank? || project.blank?

      audit_context = {
        name: 'repository_git_operation',
        stream_only: true,
        author: author,
        scope: project,
        target: project,
        message: msg
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
