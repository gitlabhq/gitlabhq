class NotePolicy < BasePolicy
  def rules
    delegate! @subject.project

    return unless @user

    if @subject.author == @user
      can! :read_note
      can! :update_note
      can! :admin_note
      can! :resolve_note
    end

    if @subject.for_merge_request? &&
       @subject.noteable.author == @user
      can! :resolve_note
    end
  end
end
