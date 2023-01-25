# frozen_string_literal: true

class IssuePresenter < Gitlab::View::Presenter::Delegated
  presents ::Issue, as: :issue

  def issue_path
    web_path
  end

  delegator_override :subscribed?
  def subscribed?
    issue.subscribed?(current_user, issue.project)
  end

  def project_emails_disabled?
    issue.project.emails_disabled?
  end

  delegator_override :service_desk_reply_to
  def service_desk_reply_to
    return unless super.present?
    return super if Ability.allowed?(current_user, :read_external_emails, issue.project)

    Gitlab::Utils::Email.obfuscated_email(super, deform: true)
  end

  delegator_override :issue_email_participants
  def issue_email_participants
    issue.issue_email_participants.present(current_user: current_user)
  end
end

IssuePresenter.prepend_mod_with('IssuePresenter')
