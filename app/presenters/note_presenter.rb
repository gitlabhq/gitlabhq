# frozen_string_literal: true

class NotePresenter < Gitlab::View::Presenter::Delegated # rubocop:disable Gitlab/NamespacedClass -- Note is not namespaced
  include MarkupHelper

  presents ::Note, as: :object # because we also have a #note method

  delegator_override :note
  def note
    obfuscate_participants_emails_in_system_note(object.note)
  end

  delegator_override :note_html
  def note_html
    # Always use `markdown_field` because it removes references based on the current user context.
    text = markdown_field(object, :note)
    obfuscate_participants_emails_in_system_note(text)
  end

  def external_author
    return unless object.note_metadata&.external_author

    if can?(current_user, :read_external_emails, object)
      object.note_metadata.external_author
    else
      Gitlab::Utils::Email.obfuscated_email(object.note_metadata.external_author, deform: true)
    end
  end

  private

  def obfuscate_participants_emails_in_system_note(text)
    return text unless object.system?
    return text if can?(current_user, :read_external_emails, object.project)
    return text if object.system_note_metadata&.action != 'issue_email_participants'

    Gitlab::Utils::Email.obfuscate_emails_in_text(text)
  end
end
