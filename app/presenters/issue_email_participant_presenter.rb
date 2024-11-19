# frozen_string_literal: true

# Model is not in a product domain namespace.
class IssueEmailParticipantPresenter < Gitlab::View::Presenter::Delegated # rubocop:disable Gitlab/NamespacedClass -- reason above
  presents ::IssueEmailParticipant, as: :participant

  delegator_override :email
  def email
    return super if Ability.allowed?(current_user, :read_external_emails, participant.issue.project)

    Gitlab::Utils::Email.obfuscated_email(super, deform: true)
  end
end
