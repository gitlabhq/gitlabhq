module Gitlab
  class GitAccess
    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }
    PUSH_COMMANDS = %w{ git-receive-pack }
    GIT_ANNEX_COMMANDS = %w{ git-annex-shell }

    attr_reader :actor, :project

    def initialize(actor, project)
      @actor    = actor
      @project  = project
    end

    def user
      return @user if defined?(@user)

      @user =
        case actor
        when User
          actor
        when DeployKey
          nil
        when GeoNodeKey
          nil
        when Key
          actor.user
        end
    end

    def deploy_key
      actor if actor.is_a?(DeployKey)
    end

    def geo_node_key
      actor if actor.is_a?(GeoNodeKey)
    end

    def can_push_to_branch?(ref)
      return false unless user

      if project.protected_branch?(ref) && !project.developers_can_push_to_protected_branch?(ref)
        user.can?(:push_code_to_protected_branches, project)
      else
        user.can?(:push_code, project)
      end
    end

    def can_read_project?
      if user
        user.can?(:read_project, project)
      elsif deploy_key
        deploy_key.projects.include?(project)
      elsif geo_node_key
        true
      else
        false
      end
    end

    def check(cmd, changes = nil)
      unless actor
        return build_status_object(false, "No user or key was provided.")
      end

      if user && !user_allowed?
        return build_status_object(false, "Your account has been blocked.")
      end

      unless project && can_read_project?
        return build_status_object(false, 'The project you were looking for could not be found.')
      end

      case cmd
      when *DOWNLOAD_COMMANDS
        download_access_check
      when *PUSH_COMMANDS
        push_access_check(changes)
      when *GIT_ANNEX_COMMANDS
        git_annex_access_check(project, changes)
      else
        build_status_object(false, "The command you're trying to execute is not allowed.")
      end
    end

    def download_access_check
      if user
        user_download_access_check
      elsif deploy_key || geo_node_key
        build_status_object(true)
      else
        raise 'Wrong actor'
      end
    end

    def push_access_check(changes)

      if Gitlab::Geo.enabled? && Gitlab::Geo.secondary?
        return build_status_object(false, "You can't push code on a secondary GitLab Geo node.")
      end

      return build_status_object(true) if git_annex_branch_sync?(changes)

      if user
        user_push_access_check(changes)
      elsif deploy_key
        build_status_object(false, "Deploy keys are not allowed to push code.")
      else
        raise 'Wrong actor'
      end
    end

    def user_download_access_check
      unless user.can?(:download_code, project)
        return build_status_object(false, "You are not allowed to download code from this project.")
      end

      build_status_object(true)
    end

    def user_push_access_check(changes)
      if changes.blank?
        return build_status_object(true)
      end

      unless project.repository.exists?
        return build_status_object(false, "A repository for this project does not exist yet.")
      end

      if ::License.block_changes?
        message = ::LicenseHelper.license_message(signed_in: true, is_admin: (user && user.is_admin?))
        return build_status_object(false, message)
      end

      changes = changes.lines if changes.kind_of?(String)

      # Iterate over all changes to find if user allowed all of them to be applied
      changes.map(&:strip).reject(&:blank?).each do |change|
        status = change_access_check(change)
        unless status.allowed?
          # If user does not have access to make at least one change - cancel all push
          return status
        end
      end

      build_status_object(true)
    end

    def change_access_check(change)
      oldrev, newrev, ref = change.split(' ')

      action =
        if project.protected_branch?(branch_name(ref))
          protected_branch_action(oldrev, newrev, branch_name(ref))
        elsif protected_tag?(tag_name(ref))
          # Prevent any changes to existing git tag unless user has permissions
          :admin_project
        else
          :push_code
        end

      unless user.can?(action, project)
        status =
          case action
          when :force_push_code_to_protected_branches
            build_status_object(false, "You are not allowed to force push code to a protected branch on this project.")
          when :remove_protected_branches
            build_status_object(false, "You are not allowed to deleted protected branches from this project.")
          when :push_code_to_protected_branches
            build_status_object(false, "You are not allowed to push code to protected branches on this project.")
          when :admin_project
            build_status_object(false, "You are not allowed to change existing tags on this project.")
          else # :push_code
            build_status_object(false, "You are not allowed to push code to this project.")
          end
        return status
      end

      # Return build_status_object(true) if all git hook checks passed successfully
      # or build_status_object(false) if any hook fails
      git_hook_check(user, project, ref, oldrev, newrev)
    end

    def forced_push?(oldrev, newrev)
      Gitlab::ForcePushCheck.force_push?(project, oldrev, newrev)
    end

    def git_hook_check(user, project, ref, oldrev, newrev)
      unless project.git_hook && newrev && oldrev
        return build_status_object(true)
      end

      git_hook = project.git_hook

      # Prevent tag removal
      if Gitlab::Git.tag_ref?(ref)
        if git_hook.deny_delete_tag && protected_tag?(tag_name(ref)) && Gitlab::Git.blank_ref?(newrev)
          return build_status_object(false, "You can not delete tag")
        end
      else
        # if newrev is blank, the branch was deleted
        if Gitlab::Git.blank_ref?(newrev) || !git_hook.commit_validation?
          return build_status_object(true)
        end

        # if oldrev is blank, the branch was just created
        oldrev = project.default_branch if Gitlab::Git.blank_ref?(oldrev)

        commits(newrev, oldrev, project).each do |commit|
          next if commit_from_annex_sync?(commit.safe_message) || old_commit?(commit)

          if status_object = check_commit(commit, git_hook)
            return status_object
          end
        end
      end

      build_status_object(true)
    end

    private

    def commits(newrev, oldrev, project)
      if oldrev
        project.repository.commits_between(oldrev, newrev)
      else
        project.repository.commits(newrev)
      end
    end

    # If commit does not pass git hook validation the whole push should be rejected.
    # This method should return nil if no error found or status object if there are some errors.
    # In case of errors - all other checks will be canceled and push will be rejected.
    def check_commit(commit, git_hook)
      unless git_hook.commit_message_allowed?(commit.safe_message)
        return build_status_object(false, "Commit message does not follow the pattern '#{git_hook.commit_message_regex}'")
      end

      unless git_hook.author_email_allowed?(commit.committer_email)
        return build_status_object(false, "Committer's email '#{commit.committer_email}' does not follow the pattern '#{git_hook.author_email_regex}'")
      end

      unless git_hook.author_email_allowed?(commit.author_email)
        return build_status_object(false, "Author's email '#{commit.author_email}' does not follow the pattern '#{git_hook.author_email_regex}'")
      end

      # Check whether author is a GitLab member
      if git_hook.member_check
        unless User.existing_member?(commit.author_email.downcase)
          return build_status_object(false, "Author '#{commit.author_email}' is not a member of team")
        end

        if commit.author_email.downcase != commit.committer_email.downcase
          unless User.existing_member?(commit.committer_email.downcase)
            return build_status_object(false, "Committer '#{commit.committer_email}' is not a member of team")
          end
        end
      end

      if status_object = check_commit_diff(commit, git_hook)
        return status_object
      end

      nil
    end

    def check_commit_diff(commit, git_hook)
      if git_hook.file_name_regex.present?
        commit.diffs.each do |diff|
          if (diff.renamed_file || diff.new_file) && diff.new_path =~ Regexp.new(git_hook.file_name_regex)
            return build_status_object(false, "File name #{diff.new_path.inspect} is prohibited by the pattern '#{git_hook.file_name_regex}'")
          end
        end
      end

      if git_hook.max_file_size > 0
        commit.diffs.each do |diff|
          next if diff.deleted_file

          blob = project.repository.blob_at(commit.id, diff.new_path)
          if blob && blob.size && blob.size > git_hook.max_file_size.megabytes
            return build_status_object(false, "File #{diff.new_path.inspect} is larger than the allowed size of #{git_hook.max_file_size} MB")
          end
        end
      end

      nil
    end

    def protected_branch_action(oldrev, newrev, branch_name)
      # we dont allow force push to protected branch
      if forced_push?(oldrev, newrev)
        :force_push_code_to_protected_branches
      elsif Gitlab::Git.blank_ref?(newrev)
        # and we dont allow remove of protected branch
        :remove_protected_branches
      elsif project.developers_can_push_to_protected_branch?(branch_name)
        :push_code
      else
        :push_code_to_protected_branches
      end
    end

    def protected_tag?(tag_name)
      project.repository.tag_names.include?(tag_name)
    end

    def user_allowed?
      Gitlab::UserAccess.allowed?(user)
    end

    def branch_name(ref)
      ref = ref.to_s
      if Gitlab::Git.branch_ref?(ref)
        Gitlab::Git.ref_name(ref)
      else
        nil
      end
    end

    def tag_name(ref)
      ref = ref.to_s
      if Gitlab::Git.tag_ref?(ref)
        Gitlab::Git.ref_name(ref)
      else
        nil
      end
    end

    def build_status_object(status, message = '')
      GitAccessStatus.new(status, message)
    end

    def git_annex_access_check(project, changes)
      unless user && user_allowed?
        return build_status_object(false, "You don't have access")
      end

      unless project.repository.exists?
        return build_status_object(false, "Repository does not exist")
      end

      if Gitlab::Geo.enabled? && Gitlab::Geo.secondary?
        return build_status_object(false, "You can't use git-annex with a secondary GitLab Geo node.")
      end

      if user.can?(:push_code, project)
        build_status_object(true)
      else
        build_status_object(false, "You don't have permission")
      end
    end

    def git_annex_branch_sync?(changes)
      return false unless Gitlab.config.gitlab_shell.git_annex_enabled
      return false if changes.blank?

      changes = changes.lines if changes.kind_of?(String)

      # Iterate over all changes to find if user allowed all of them to be applied
      # 0000000000000000000000000000000000000000 3073696294ddd52e9e6b6fc3f429109cac24626f refs/heads/synced/git-annex
      # 0000000000000000000000000000000000000000 65be9df0e995d36977e6d76fc5801b7145ce19c9 refs/heads/synced/master
      changes.map(&:strip).reject(&:blank?).each do |change|
        unless change.end_with?("refs/heads/synced/git-annex") || change.include?("refs/heads/synced/")
          return false
        end
      end

      true
    end

    def commit_from_annex_sync?(commit_message)
      return false unless Gitlab.config.gitlab_shell.git_annex_enabled

      # Commit message starting with <git-annex in > so avoid git hooks on this
      commit_message.start_with?('git-annex in')
    end

    def old_commit?(commit)
      commit.refs(project.repository).any?
    end
  end
end
