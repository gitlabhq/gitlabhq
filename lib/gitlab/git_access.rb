module Gitlab
  class GitAccess
    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }
    PUSH_COMMANDS = %w{ git-receive-pack }

    attr_reader :params, :project, :git_cmd, :user

    def allowed?(actor, cmd, project, ref = nil, oldrev = nil, newrev = nil)
      case cmd
      when *DOWNLOAD_COMMANDS
        if actor.is_a? User
          download_allowed?(actor, project)
        elsif actor.is_a? DeployKey
          actor.projects.include?(project)
        elsif actor.is_a? Key
          download_allowed?(actor.user, project)
        else
          raise 'Wrong actor'
        end
      when *PUSH_COMMANDS
        if actor.is_a? User
          push_allowed?(actor, project, ref, oldrev, newrev)
        elsif actor.is_a? DeployKey
          # Deploy key not allowed to push
          return false
        elsif actor.is_a? Key
          push_allowed?(actor.user, project, ref, oldrev, newrev)
        else
          raise 'Wrong actor'
        end
      else
        false
      end
    end

    def download_allowed?(user, project)
      if user && user_allowed?(user)
        user.can?(:download_code, project)
      else
        false
      end
    end

    def push_allowed?(user, project, ref, oldrev, newrev)
      if user && user_allowed?(user)
        action = if project.protected_branch?(ref)
                   :push_code_to_protected_branches
                 else
                   :push_code
                 end
        user.can?(action, project)
      else
        false
      end
    end

    private

    def user_allowed?(user)
      return false if user.blocked?

      if Gitlab.config.ldap.enabled
        if user.ldap_user?
          # Check if LDAP user exists and match LDAP user_filter
          unless Gitlab::LDAP::Access.new.allowed?(user)
            return false
          end
        end
      end

      true
    end
  end
end
