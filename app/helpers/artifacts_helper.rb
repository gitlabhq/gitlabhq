# frozen_string_literal: true

module ArtifactsHelper
  def artifacts_app_data(project)
    {
      project_path: project.full_path,
      project_id: project.id,
      can_destroy_artifacts: can?(current_user, :destroy_artifacts, project).to_s,
      artifacts_management_feedback_image_path: image_path('illustrations/chat-bubble-sm.svg')
    }
  end
end
