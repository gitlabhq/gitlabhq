# frozen_string_literal: true

class DraftNotePolicy < BasePolicy
  delegate { @subject.merge_request }

  condition(:is_author) { @user && @subject.author == @user }

  rule { is_author }.policy do
    enable :read_note
    enable :admin_note
    enable :resolve_note
  end
end
