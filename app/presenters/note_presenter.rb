# frozen_string_literal: true

class NotePresenter < Gitlab::View::Presenter::Delegated # rubocop:disable Gitlab/NamespacedClass -- Note is not namespaced
  presents ::Note, as: :object # because we also have a #note method

  delegator_override :note
  def note
    obfuscate_participants_emails_in_system_note(object.note)
  end

  delegator_override :note_html
  def note_html
    # Always use `redacted_note_html` because it removes references
    # based on the current user context.
    # But fall back to `note_html` if redacted is not available (same behavior as `markdown_field`)
    obfuscate_participants_emails_in_system_note(object.redacted_note_html || object.note_html)
  end

  private

  def obfuscate_participants_emails_in_system_note(text)
    return text unless object.system?
    return text if can?(current_user, :read_external_emails, object.project)
    return text if object.system_note_metadata&.action != 'issue_email_participants'

    Gitlab::Utils::Email.obfuscate_emails_in_text(text)
  end
end
