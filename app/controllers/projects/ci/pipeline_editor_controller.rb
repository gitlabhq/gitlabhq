# frozen_string_literal: true

class Projects::Ci::PipelineEditorController < Projects::ApplicationController
  before_action :check_can_collaborate!
  before_action do
    push_frontend_feature_flag(:pipeline_editor_empty_state_action, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:pipeline_editor_branch_switcher, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:pipeline_editor_drawer, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:schema_linting, @project, default_enabled: :yaml)
  end

  feature_category :pipeline_authoring

  def show
  end

  private

  def check_can_collaborate!
    render_404 unless can_collaborate_with_project?(@project)
  end
end
