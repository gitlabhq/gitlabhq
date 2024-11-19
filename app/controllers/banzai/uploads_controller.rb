# frozen_string_literal: true

module Banzai
  class UploadsController < ApplicationController
    include UploadsActions

    skip_before_action :authenticate_user!
    skip_before_action :check_two_factor_requirement

    before_action :verify_upload_model_class!
    before_action :authorize_access!

    feature_category :markdown

    MODEL_CLASSES = {
      'project' => Project,
      'group' => Group
    }.freeze

    private

    def verify_upload_model_class!
      render_404 if upload_model_class.nil?
    end

    def authorize_access!
      return if bypass_auth_checks_on_uploads?

      render_404 unless can?(current_user, :"read_#{model.to_ability_name}", model)
    end

    def upload_model_class
      MODEL_CLASSES[params[:model]]
    end

    def uploader_class
      case model
      when Project
        FileUploader
      when Group
        NamespaceFileUploader
      end
    end

    def target_project
      model if model.is_a?(Project)
    end

    def find_model
      upload_model_class.find(params[:model_id])
    end
  end
end
