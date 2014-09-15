module Gitlab
  class GitAccess
    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }
    PUSH_COMMANDS = %w{ git-receive-pack }

    attr_reader :params, :project, :git_cmd, :user

    def allowed?(actor, cmd, project, changes = nil)
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
          push_allowed?(actor, project, changes)
        elsif actor.is_a? DeployKey
          # Deploy key not allowed to push
          return false
        elsif actor.is_a? Key
          push_allowed?(actor.user, project, changes)
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

    def push_allowed?(user, project, changes)
      return false unless user && user_allowed?(user)
      return true if changes.blank?

      changes = changes.lines if changes.kind_of?(String)

      # Iterate over all changes to find if user allowed all of them to be applied
      changes.each do |change|
        oldrev, newrev, ref = changes.split('')

        action = if project.protected_branch?(ref)
                   # we dont allow force push to protected branch
                   if forced_push?(oldrev, newrev)
                     :force_push_code_to_protected_branches
                     # and we dont allow remove of protected branch
                   elsif newrev =~ /0000000/
                     :remove_protected_branches
                   else
                     :push_code_to_protected_branches
                   end
                 elsif project.repository && project.repository.tag_names.include?(ref)
                   # Prevent any changes to existing git tag unless user has permissions
                   :admin_project
                 else
                   :push_code
                 end
        unless user.can?(action, project) &&
          pass_git_hooks?(user, project, ref, oldrev, newrev)
          # If user does not have access to make at least one change - cancel all push
          return false
        end
      end

      # If user has access to make all changes
      true
    end

    def forced_push?(oldrev, newrev)
      return false if project.empty_repo?

      if oldrev !~ /00000000/ && newrev !~ /00000000/
        missed_refs = IO.popen(%W(git --git-dir=#{project.repository.path_to_repo} rev-list #{oldrev} ^#{newrev})).read
        missed_refs.split("\n").size > 0
      else
        false
      end
    end

    def pass_git_hooks?(user, project, ref, oldrev, newrev)
      return true unless project.git_hook

      return true unless newrev && oldrev

      git_hook = project.git_hook

      # Prevent tag removal
      if git_hook.deny_delete_tag
        if project.repository.tag_names.include?(ref) && newrev =~ /0000000/
          return false
        end
      end

      # Check commit messages unless its branch removal
      if git_hook.commit_message_regex.present? && newrev !~ /00000000/
        commits = project.repository.commits_between(oldrev, newrev)
        commits.each do |commit|
          unless commit.safe_message =~ Regexp.new(git_hook.commit_message_regex)
            return false
          end
        end
      end

      true
    end

    private

    def user_allowed?(user)
      Gitlab::UserAccess.allowed?(user)
    end
  end
end
