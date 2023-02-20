# frozen_string_literal: true

class IssueEmailParticipantPresenter < Gitlab::View::Presenter::Delegated
  presents ::IssueEmailParticipant, as: :participant

  delegator_override :email
  def email
    return super if Ability.allowed?(current_user, :read_external_emails, participant.issue.project)

    Gitlab::Utils::Email.obfuscated_email(super, deform: true)
  end
end
