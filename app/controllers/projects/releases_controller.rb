# frozen_string_literal: true

class Projects::ReleasesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_read_release!
  before_action do
    push_frontend_feature_flag(:release_edit_page, project)
  end

  def index
  end
end
