# frozen_string_literal: true

class Projects::Ci::SecureFilesController < Projects::ApplicationController
  before_action :authorize_read_secure_files!

  feature_category :pipeline_authoring

  def show
  end
end
