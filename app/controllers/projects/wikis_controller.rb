# frozen_string_literal: true

class Projects::WikisController < Projects::ApplicationController
  include WikiActions

  alias_method :container, :project

  before_action do
    push_frontend_feature_flag(:content_editor_block_tables, @project, default_enabled: :yaml)
  end

  feature_category :wiki
end
