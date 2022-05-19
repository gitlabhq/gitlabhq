# frozen_string_literal: true

class Projects::Ci::SecureFilesController < Projects::ApplicationController
  before_action :authorize_read_secure_files!

  feature_category :pipeline_authoring

  def show
    render_404 unless Feature.enabled?(:ci_secure_files, project)
  end
end
