# frozen_string_literal: true

class NotePolicy < BasePolicy
  delegate { @subject.project }
  delegate { @subject.noteable if DeclarativePolicy.has_policy?(@subject.noteable) }

  condition(:is_author) { @user && @subject.author == @user }
  condition(:is_noteable_author) { @user && @subject.noteable.author_id == @user.id }

  condition(:editable, scope: :subject) { @subject.editable? }

  condition(:can_read_noteable) { can?(:"read_#{@subject.to_ability_name}") }

  rule { ~editable }.prevent :admin_note

  # If user can't read the issue/MR/etc then they should not be allowed to do anything to their own notes
  rule { ~can_read_noteable }.policy do
    prevent :read_note
    prevent :admin_note
    prevent :resolve_note
    prevent :award_emoji
  end

  rule { is_author }.policy do
    enable :read_note
    enable :admin_note
    enable :resolve_note
  end

  rule { is_noteable_author }.policy do
    enable :resolve_note
  end
end
