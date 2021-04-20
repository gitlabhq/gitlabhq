# frozen_string_literal: true

module LearnGitlabHelper
  def learn_gitlab_experiment_enabled?(project)
    return false unless current_user
    return false unless experiment_enabled_for_user?

    learn_gitlab_onboarding_available?(project)
  end

  def onboarding_actions_data(project)
    attributes = onboarding_progress(project).attributes.symbolize_keys

    action_urls.to_h do |action, url|
      [
        action,
        url: url,
        completed: attributes[OnboardingProgress.column_name(action)].present?,
        svg: image_path("learn_gitlab/#{action}.svg")
      ]
    end
  end

  private

  ACTION_ISSUE_IDS = {
    issue_created: 4,
    git_write: 6,
    pipeline_created: 7,
    merge_request_created: 9,
    user_added: 8,
    trial_started: 2,
    required_mr_approvals_enabled: 11,
    code_owners_enabled: 10
  }.freeze

  ACTION_DOC_URLS = {
    security_scan_enabled: 'https://docs.gitlab.com/ee/user/application_security/security_dashboard/#gitlab-security-dashboard-security-center-and-vulnerability-reports'
  }.freeze

  def action_urls
    ACTION_ISSUE_IDS.transform_values { |id| project_issue_url(learn_gitlab_project, id) }.merge(ACTION_DOC_URLS)
  end

  def learn_gitlab_project
    @learn_gitlab_project ||= LearnGitlab.new(current_user).project
  end

  def onboarding_progress(project)
    OnboardingProgress.find_by(namespace: project.namespace) # rubocop: disable CodeReuse/ActiveRecord
  end

  def experiment_enabled_for_user?
    Gitlab::Experimentation.in_experiment_group?(:learn_gitlab_a, subject: current_user) ||
      Gitlab::Experimentation.in_experiment_group?(:learn_gitlab_b, subject: current_user)
  end

  def learn_gitlab_onboarding_available?(project)
    OnboardingProgress.onboarding?(project.namespace) &&
      LearnGitlab.new(current_user).available?
  end
end
