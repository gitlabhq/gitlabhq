# Check a user's access to perform a git action. All public methods in this
# class return an instance of `GitlabAccessStatus`
module Gitlab
  class GitAccess
    include PathLocksHelper

    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }
    PUSH_COMMANDS = %w{ git-receive-pack }
    GIT_ANNEX_COMMANDS = %w{ git-annex-shell }

    attr_reader :actor, :project, :protocol, :user_access

    def initialize(actor, project, protocol)
      @actor    = actor
      @project  = project
      @protocol = protocol
      @user_access = UserAccess.new(user, project: project)
    end

    def check(cmd, changes)
      return build_status_object(false, "Git access over #{protocol.upcase} is not allowed") unless protocol_allowed?

      unless actor
        return build_status_object(false, "No user or key was provided.")
      end

      if user && !user_access.allowed?
        return build_status_object(false, "Your account has been blocked.")
      end

      unless project && (user_access.can_read_project? || deploy_key_can_read_project? || geo_node_key)
        return build_status_object(false, 'The project you were looking for could not be found.')
      end

      if Gitlab::Geo.secondary? && !Gitlab::Geo.license_allows?
        return build_status_object(false, 'Your current license does not have GitLab Geo add-on enabled.')
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
      if project.repository_read_only?
        return build_status_object(false, 'The repository is temporarily read-only. Please try again later.')
      end

      if Gitlab::Geo.secondary?
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
      unless user_access.can_do_action?(:download_code)
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

      changes_list = Gitlab::ChangesList.new(changes)

      # Iterate over all changes to find if user allowed all of them to be applied
      changes_list.each do |change|
        status = change_access_check(change)
        unless status.allowed?
          # If user does not have access to make at least one change - cancel all push
          return status
        end
      end

      build_status_object(true)
    end

    def change_access_check(change)
      Checks::ChangeAccess.new(change, user_access: user_access, project: project).exec
    end

    def protocol_allowed?
      Gitlab::ProtocolAccess.allowed?(protocol)
    end

    def matching_merge_request?(newrev, branch_name)
      Checks::MatchingMergeRequest.new(newrev, branch_name, project).match?
    end

    private

    def commits(newrev, oldrev, project)
      if oldrev
        project.repository.commits_between(oldrev, newrev)
      else
        project.repository.commits(newrev)
      end
    end

    # If commit does not pass push rule validation the whole push should be rejected.
    # This method should return nil if no error found or status object if there are some errors.
    # In case of errors - all other checks will be canceled and push will be rejected.
    def check_commit(commit, push_rule)
      unless push_rule.commit_message_allowed?(commit.safe_message)
        return build_status_object(false, "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'")
      end

      unless push_rule.author_email_allowed?(commit.committer_email)
        return build_status_object(false, "Committer's email '#{commit.committer_email}' does not follow the pattern '#{push_rule.author_email_regex}'")
      end

      unless push_rule.author_email_allowed?(commit.author_email)
        return build_status_object(false, "Author's email '#{commit.author_email}' does not follow the pattern '#{push_rule.author_email_regex}'")
      end

      # Check whether author is a GitLab member
      if push_rule.member_check
        unless User.existing_member?(commit.author_email.downcase)
          return build_status_object(false, "Author '#{commit.author_email}' is not a member of team")
        end

        if commit.author_email.casecmp(commit.committer_email) == -1
          unless User.existing_member?(commit.committer_email.downcase)
            return build_status_object(false, "Committer '#{commit.committer_email}' is not a member of team")
          end
        end
      end

      if status_object = check_commit_diff(commit, push_rule)
        return status_object
      end

      nil
    end

    def check_commit_diff(commit, push_rule)
      if push_rule.file_name_regex.present?
        commit.raw_diffs.each do |diff|
          if (diff.renamed_file || diff.new_file) && diff.new_path =~ Regexp.new(push_rule.file_name_regex)
            return build_status_object(false, "File name #{diff.new_path.inspect} is prohibited by the pattern '#{push_rule.file_name_regex}'")
          end
        end
      end

      if push_rule.max_file_size > 0
        commit.raw_diffs.each do |diff|
          next if diff.deleted_file

          blob = project.repository.blob_at(commit.id, diff.new_path)
          if blob && blob.size && blob.size > push_rule.max_file_size.megabytes
            return build_status_object(false, "File #{diff.new_path.inspect} is larger than the allowed size of #{push_rule.max_file_size} MB")
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
      elsif matching_merge_request?(newrev, branch_name) && project.developers_can_merge_to_protected_branch?(branch_name)
        :push_code
      elsif project.developers_can_push_to_protected_branch?(branch_name)
        :push_code
      else
        :push_code_to_protected_branches
      end
    end

    def protected_tag?(tag_name)
      project.repository.tag_exists?(tag_name)
    end

    def deploy_key
      actor if actor.is_a?(DeployKey)
    end

    def geo_node_key
      actor if actor.is_a?(GeoNodeKey)
    end

    def deploy_key_can_read_project?
      if deploy_key
        return true if project.public?
        deploy_key.projects.include?(project)
      else
        false
      end
    end

    protected

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

    def build_status_object(status, message = '')
      Gitlab::GitAccessStatus.new(status, message)
    end

    def git_annex_access_check(project, changes)
      return build_status_object(false, "git-annex is disabled") unless Gitlab.config.gitlab_shell.git_annex_enabled

      unless user && user_access.allowed?
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

      # Commit message starting with <git-annex in > so avoid push rules on this
      commit_message.start_with?('git-annex in')
    end

    def old_commit?(commit)
      commit.refs(project.repository).any?
    end
  end
end
