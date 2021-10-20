# frozen_string_literal: true

class IssuePresenter < Gitlab::View::Presenter::Delegated
  presents ::Issue, as: :issue

  def issue_path
    url_builder.build(issue, only_path: true)
  end

  delegator_override :subscribed?
  def subscribed?
    issue.subscribed?(current_user, issue.project)
  end

  def project_emails_disabled?
    issue.project.emails_disabled?
  end
end

IssuePresenter.prepend_mod_with('IssuePresenter')
