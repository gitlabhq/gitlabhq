# frozen_string_literal: true

class IssuePresenter < Gitlab::View::Presenter::Delegated
  presents ::Issue, as: :issue

  def issue_path
    return url_builder.build(issue, only_path: true) unless use_work_items_path?

    project_work_items_path(issue.project, work_items_path: issue.id)
  end

  delegator_override :subscribed?
  def subscribed?
    issue.subscribed?(current_user, issue.project)
  end

  def project_emails_disabled?
    issue.project.emails_disabled?
  end

  def web_url
    return super unless use_work_items_path?

    project_work_items_url(issue.project, work_items_path: issue.id)
  end

  private

  def use_work_items_path?
    issue.issue_type == 'task' && issue.project.work_items_feature_flag_enabled?
  end
end

IssuePresenter.prepend_mod_with('IssuePresenter')
