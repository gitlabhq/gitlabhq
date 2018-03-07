class NotePolicy < BasePolicy
  delegate { @subject.project }
  delegate { @subject.noteable if @subject.noteable.lockable? }

  condition(:is_author) { @user && @subject.author == @user }
  condition(:for_merge_request, scope: :subject) { @subject.for_merge_request? }
  condition(:is_noteable_author) { @user && @subject.noteable.author_id == @user.id }

  condition(:editable, scope: :subject) { @subject.editable? }

  rule { ~editable | anonymous }.prevent :edit_note

  rule { is_author | admin }.enable :edit_note
  rule { can?(:master_access) }.enable :edit_note

  rule { is_author }.policy do
    enable :read_note
    enable :update_note
    enable :admin_note
    enable :resolve_note
  end

  rule { for_merge_request & is_noteable_author }.policy do
    enable :resolve_note
  end
end
