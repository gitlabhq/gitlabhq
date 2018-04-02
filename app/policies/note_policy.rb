class NotePolicy < BasePolicy
  delegate { @subject.project }
  delegate { @subject.noteable if @subject.noteable.lockable? }

  condition(:is_author) { @user && @subject.author == @user }
  condition(:is_noteable_author) { @user && @subject.noteable.author_id == @user.id }

  condition(:editable, scope: :subject) { @subject.editable? }

  rule { ~editable }.prevent :admin_note

  rule { is_author }.policy do
    enable :read_note
    enable :admin_note
    enable :resolve_note
  end

  rule { is_noteable_author }.policy do
    enable :resolve_note
  end
end
