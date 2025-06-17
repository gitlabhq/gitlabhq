# frozen_string_literal: true

class Projects::Ci::PipelineEditorController < Projects::ApplicationController
  before_action :check_can_collaborate!
  before_action do
    push_frontend_feature_flag(:ci_job_assistant_drawer, @project)
  end

  feature_category :pipeline_composition

  urgency :low, [:show]

  def show; end

  private

  def check_can_collaborate!
    render_404 unless can_collaborate_with_project?(@project)
  end
end

Projects::Ci::PipelineEditorController.prepend_mod
