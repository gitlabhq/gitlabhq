# frozen_string_literal: true

class Projects::Ci::PipelineEditorController < Projects::ApplicationController
  before_action :check_can_collaborate!
  before_action :setup_walkthrough_experiment, only: :show
  before_action do
    push_frontend_feature_flag(:schema_linting, @project, default_enabled: :yaml)
  end

  feature_category :pipeline_authoring

  def show
  end

  private

  def check_can_collaborate!
    render_404 unless can_collaborate_with_project?(@project)
  end

  def setup_walkthrough_experiment
    experiment(:pipeline_editor_walkthrough, namespace: @project.namespace, sticky_to: current_user) do |e|
      e.candidate {}
      e.record!
    end
  end
end
