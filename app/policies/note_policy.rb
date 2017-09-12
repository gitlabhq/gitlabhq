class NotePolicy < BasePolicy
  delegate { @subject.project }
  delegate { @subject.noteable if @subject.noteable.lockable? }

  condition(:is_author) { @user && @subject.author == @user }
  condition(:is_project_member) { @user && @subject.project && @subject.project.team.member?(@user) }
  condition(:for_merge_request, scope: :subject) { @subject.for_merge_request? }
  condition(:is_noteable_author) { @user && @subject.noteable.author_id == @user.id }

  condition(:editable, scope: :subject) { @subject.editable? }
  condition(:locked) { [MergeRequest, Issue].include?(@subject.noteable.class) && @subject.noteable.discussion_locked? }

  rule { ~editable | anonymous }.prevent :edit_note

  rule { is_author | admin }.enable :edit_note
  rule { can?(:master_access) }.enable :edit_note
  rule { locked & ~is_author & ~is_project_member }.prevent :edit_note

  rule { is_author }.policy do
    enable :read_note
    enable :update_note
    enable :admin_note
    enable :resolve_note
  end

  rule { for_merge_request & is_noteable_author }.policy do
    enable :resolve_note
  end

  rule { locked & ~is_project_member }.policy do
    prevent :update_note
    prevent :admin_note
    prevent :resolve_note
  end
end
