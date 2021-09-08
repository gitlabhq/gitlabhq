# frozen_string_literal: true

class Projects::WorkItemsController < Projects::ApplicationController
  before_action do
    push_frontend_feature_flag(:work_items, project, default_enabled: :yaml)
  end

  feature_category :not_owned

  def index
  end
end
