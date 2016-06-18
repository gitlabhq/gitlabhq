module Commits
  class RevertService < ChangeService
    def commit
      revert_into = @create_merge_request ? @commit.revert_branch_name : @target_branch
      revert_tree_id = repository.check_revert_content(@commit, @target_branch)

      if revert_tree_id
        create_target_branch(revert_into) if @create_merge_request

        repository.revert(current_user, @commit, revert_into, revert_tree_id)
        success
      else
        error_msg = "Sorry, we cannot revert this #{@commit.change_type_title} automatically.
                     It may have already been reverted, or a more recent commit may have updated some of its content."
        raise ChangeError, error_msg
      end
    end
  end
end
