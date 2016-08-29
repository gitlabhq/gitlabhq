module Ci
  class LintsController < ApplicationController
    before_action :authenticate_user!

    def show
    end

    def create
      @content = params[:content]
      @error = Ci::GitlabCiYamlProcessor.validation_message(@content)

      unless @error.blank?
        @status = @error.blank?
      else
        @config_processor = Ci::GitlabCiYamlProcessor.new(@content)
        @stages = @config_processor.stages
        @builds = @config_processor.builds
        @status = true
      end
    rescue
      @error = 'Undefined error'
      @status = false
    ensure
      render :show
    end
  end
end
