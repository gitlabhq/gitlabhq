module Commits
  class CherryPickService < ChangeService
    def commit
      cherry_pick_into = @create_merge_request ? @commit.cherry_pick_branch_name : @target_branch
      cherry_pick_tree_id = repository.check_cherry_pick_content(@commit, @target_branch)

      if cherry_pick_tree_id
        create_target_branch(cherry_pick_into) if @create_merge_request

        repository.cherry_pick(current_user, @commit, cherry_pick_into, cherry_pick_tree_id)
        success
      else
        error_msg = "Sorry, we cannot cherry-pick this #{@commit.change_type_title} automatically.
                     It may have already been cherry-picked, or a more recent commit may have updated some of its content."
        raise ChangeError, error_msg
      end
    end
  end
end
