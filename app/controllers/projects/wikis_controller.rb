# frozen_string_literal: true

class Projects::WikisController < Projects::ApplicationController
  include WikiActions

  alias_method :container, :project

  feature_category :wiki

  before_action do
    push_frontend_feature_flag(:wiki_content_editor, project, default_enabled: :yaml)
  end
end
