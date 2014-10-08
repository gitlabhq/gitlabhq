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
        unless change_allowed?(user, project, change)
          # If user does not have access to make at least one change - cancel all push
          return false
        end
      end

      # If user has access to make all changes
      true
    end

    def change_allowed?(user, project, change)
      oldrev, newrev, ref = change.split(' ')

      action = if project.protected_branch?(branch_name(ref))
                 # we dont allow force push to protected branch
                 if forced_push?(project, oldrev, newrev)
                   :force_push_code_to_protected_branches
                   # and we dont allow remove of protected branch
                 elsif newrev =~ /0000000/
                   :remove_protected_branches
                 else
                   :push_code_to_protected_branches
                 end
               elsif project.repository && project.repository.tag_names.include?(tag_name(ref))
                 # Prevent any changes to existing git tag unless user has permissions
                 :admin_project
               else
                 :push_code
               end

      user.can?(action, project)
    end

    def forced_push?(project, oldrev, newrev)
      return false if project.empty_repo?

      if oldrev !~ /00000000/ && newrev !~ /00000000/
        missed_refs = IO.popen(%W(git --git-dir=#{project.repository.path_to_repo} rev-list #{oldrev} ^#{newrev})).read
        missed_refs.split("\n").size > 0
      else
        false
      end
    end

    private

    def user_allowed?(user)
      Gitlab::UserAccess.allowed?(user)
    end

    def branch_name(ref)
      ref = ref.to_s
      if ref.start_with?('refs/heads')
        ref.sub(%r{\Arefs/heads/}, '')
      else
        nil
      end
    end

    def tag_name(ref)
      ref = ref.to_s
      if ref.start_with?('refs/tags')
        ref.sub(%r{\Arefs/tags/}, '')
      else
        nil
      end
    end
  end
end
