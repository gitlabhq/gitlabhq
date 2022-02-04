# frozen_string_literal: true

module LearnGitlabHelper
  def learn_gitlab_enabled?(project)
    return false unless current_user

    learn_gitlab_onboarding_available?(project)
  end

  def learn_gitlab_data(project)
    {
      actions: onboarding_actions_data(project).to_json,
      sections: onboarding_sections_data.to_json,
      project: onboarding_project_data(project).to_json
    }
  end

  def learn_gitlab_onboarding_available?(project)
    OnboardingProgress.onboarding?(project.namespace) &&
      LearnGitlab::Project.new(current_user).available?
  end

  private

  def onboarding_actions_data(project)
    attributes = onboarding_progress(project).attributes.symbolize_keys

    urls_to_use = nil

    experiment(
      :change_continuous_onboarding_link_urls,
      namespace: project.namespace,
      actor: current_user,
      sticky_to: project.namespace
    ) do |e|
      e.control { urls_to_use = action_urls }
      e.candidate { urls_to_use = new_action_urls(project) }
    end

    urls_to_use.to_h do |action, url|
      [
        action,
        url: url,
        completed: attributes[OnboardingProgress.column_name(action)].present?,
        svg: image_path("learn_gitlab/#{action}.svg")
      ]
    end
  end

  def onboarding_sections_data
    {
      workspace: {
        svg: image_path("learn_gitlab/section_workspace.svg")
      },
      plan: {
        svg: image_path("learn_gitlab/section_plan.svg")
      },
      deploy: {
        svg: image_path("learn_gitlab/section_deploy.svg")
      }
    }
  end

  def onboarding_project_data(project)
    { name: project.name }
  end

  def action_urls
    LearnGitlab::Onboarding::ACTION_ISSUE_IDS.transform_values { |id| project_issue_url(learn_gitlab_project, id) }
      .merge(LearnGitlab::Onboarding::ACTION_DOC_URLS)
  end

  def new_action_urls(project)
    action_urls.merge(
      issue_created: project_issues_path(project),
      git_write: project_path(project),
      pipeline_created: project_pipelines_path(project),
      merge_request_created: project_merge_requests_path(project),
      user_added: project_members_url(project),
      security_scan_enabled: project_security_configuration_path(project)
    )
  end

  def learn_gitlab_project
    @learn_gitlab_project ||= LearnGitlab::Project.new(current_user).project
  end

  def onboarding_progress(project)
    OnboardingProgress.find_by(namespace: project.namespace) # rubocop: disable CodeReuse/ActiveRecord
  end
end

LearnGitlabHelper.prepend_mod_with('LearnGitlabHelper')
