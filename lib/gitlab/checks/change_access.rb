module Gitlab
  module Checks
    class ChangeAccess
      include PathLocksHelper
      attr_reader :user_access, :project

      def initialize(change, user_access:, project:)
        @oldrev, @newrev, @ref = change.values_at(:oldrev, :newrev, :ref)
        @branch_name = Gitlab::Git.branch_name(@ref)
        @user_access = user_access
        @project = project
      end

      def exec
        error = push_checks || tag_checks || protected_branch_checks || push_rules_checks

        if error
          GitAccessStatus.new(false, error)
        else
          GitAccessStatus.new(true)
        end
      end

      protected

      def protected_branch_checks
        return unless project.protected_branch?(@branch_name)

        if forced_push? && user_access.cannot_do_action?(:force_push_code_to_protected_branches)
          return "You are not allowed to force push code to a protected branch on this project."
        elsif Gitlab::Git.blank_ref?(@newrev) && user_access.cannot_do_action?(:remove_protected_branches)
          return "You are not allowed to delete protected branches from this project."
        end

        if matching_merge_request?
          if user_access.can_merge_to_branch?(@branch_name) || user_access.can_push_to_branch?(@branch_name)
            return
          else
            "You are not allowed to merge code into protected branches on this project."
          end
        else
          if user_access.can_push_to_branch?(@branch_name)
            return
          else
            "You are not allowed to push code to protected branches on this project."
          end
        end
      end

      def tag_checks
        tag_ref = Gitlab::Git.tag_name(@ref)

        if tag_ref && protected_tag?(tag_ref) && user_access.cannot_do_action?(:admin_project)
          "You are not allowed to change existing tags on this project."
        end
      end

      def push_checks
        if user_access.cannot_do_action?(:push_code)
          "You are not allowed to push code to this project."
        end
      end

      def push_rules_checks
        # Returns nil if all push rule checks passed successfully
        # or the error if any hook fails
        error = push_rule_check

        if !error && license_allows_file_locks?
          error = path_locks_check
        end

        error
      end

      private

      def protected_tag?(tag_name)
        project.repository.tag_exists?(tag_name)
      end

      def forced_push?
        Gitlab::Checks::ForcePush.force_push?(@project, @oldrev, @newrev)
      end

      def matching_merge_request?
        Checks::MatchingMergeRequest.new(@newrev, @branch_name, @project).match?
      end

      def push_rule_check
        return unless project.push_rule && @newrev && @oldrev

        push_rule = project.push_rule

        # Prevent tag removal
        if Gitlab::Git.tag_name(@ref)
          if push_rule.deny_delete_tag && protected_tag?(Gitlab::Git.tag_name(@ref)) && Gitlab::Git.blank_ref?(@newrev)
            "You can not delete tag"
          end
        else
          # if newrev is blank, the branch was deleted
          return if Gitlab::Git.blank_ref?(@newrev) || !push_rule.commit_validation?

          commits.each do |commit|
            next if commit_from_annex_sync?(commit.safe_message)

            if error = check_commit(commit, push_rule)
              return error
            end
          end
        end

        nil
      end

      def path_locks_check
        return unless project.path_locks.any? && @newrev && @oldrev

        # locks protect default branch only
        return if project.default_branch != branch_name(@ref)

        commits.each do |commit|
          next if commit_from_annex_sync?(commit.safe_message)

          commit.raw_diffs.each do |diff|
            path = diff.new_path || diff.old_path

            lock_info = project.find_path_lock(path)

            if lock_info && lock_info.user != user_access.user
              return "The path '#{lock_info.path}' is locked by #{lock_info.user.name}"
            end
          end
        end

        nil
      end

      # If commit does not pass push rule validation the whole push should be rejected.
      # This method should return nil if no error found or status object if there are some errors.
      # In case of errors - all other checks will be canceled and push will be rejected.
      def check_commit(commit, push_rule)
        unless push_rule.commit_message_allowed?(commit.safe_message)
          return "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'"
        end

        unless push_rule.author_email_allowed?(commit.committer_email)
          return "Committer's email '#{commit.committer_email}' does not follow the pattern '#{push_rule.author_email_regex}'"
        end

        unless push_rule.author_email_allowed?(commit.author_email)
          return "Author's email '#{commit.author_email}' does not follow the pattern '#{push_rule.author_email_regex}'"
        end

        # Check whether author is a GitLab member
        if push_rule.member_check
          unless User.existing_member?(commit.author_email.downcase)
            return "Author '#{commit.author_email}' is not a member of team"
          end

          if commit.author_email.casecmp(commit.committer_email) == -1
            unless User.existing_member?(commit.committer_email.downcase)
              return "Committer '#{commit.committer_email}' is not a member of team"
            end
          end
        end

        if error = check_commit_diff(commit, push_rule)
          return error
        end

        nil
      end

      def check_commit_diff(commit, push_rule)
        if push_rule.file_name_regex.present?
          commit.raw_diffs.each do |diff|
            if (diff.renamed_file || diff.new_file) && diff.new_path =~ Regexp.new(push_rule.file_name_regex)
              return "File name #{diff.new_path.inspect} is prohibited by the pattern '#{push_rule.file_name_regex}'"
            end
          end
        end

        if push_rule.max_file_size > 0
          commit.raw_diffs.each do |diff|
            next if diff.deleted_file

            blob = project.repository.blob_at(commit.id, diff.new_path)
            if blob && blob.size && blob.size > push_rule.max_file_size.megabytes
              return "File #{diff.new_path.inspect} is larger than the allowed size of #{push_rule.max_file_size} MB"
            end
          end
        end

        nil
      end

      def commits
        project.repository.new_commits(@newrev)
      end

      def commit_from_annex_sync?(commit_message)
        return false unless Gitlab.config.gitlab_shell.git_annex_enabled

        # Commit message starting with <git-annex in > so avoid push rules on this
        commit_message.start_with?('git-annex in')
      end
    end
  end
end
