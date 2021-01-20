# frozen_string_literal: true

class Projects::Ci::PipelineEditorController < Projects::ApplicationController
  before_action :check_can_collaborate!
  before_action do
    push_frontend_feature_flag(:ci_config_visualization_tab, @project, default_enabled: :yaml)
  end

  feature_category :pipeline_authoring

  def show
    render_404 unless ::Gitlab::Ci::Features.ci_pipeline_editor_page_enabled?(@project)
  end

  private

  def check_can_collaborate!
    render_404 unless can_collaborate_with_project?(@project)
  end
end
