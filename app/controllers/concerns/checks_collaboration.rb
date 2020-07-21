# frozen_string_literal: true

module ChecksCollaboration
  def can_collaborate_with_project?(project, ref: nil)
    return true if can?(current_user, :push_code, project)

    can_create_merge_request =
      can?(current_user, :create_merge_request_in, project) &&
      current_user.already_forked?(project)

    can_create_merge_request ||
      user_access(project).can_push_to_branch?(ref)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  # enabling this so we can easily cache the user access value as it might be
  # used across multiple calls in the view
  def user_access(project)
    @user_access ||= {}
    @user_access[project] ||= Gitlab::UserAccess.new(current_user, container: project)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
