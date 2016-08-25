module Ci
  class LintsController < ApplicationController
    before_action :authenticate_user!

    def show
    end

    def create
      @content = params[:content]

      if @content.blank?
        @status = false
        @error = "Please provide content of .gitlab-ci.yml"
      elsif !Ci::GitlabCiYamlProcessor.errors(@content).nil?
        @status = false
        @error = Ci::GitlabCiYamlProcessor.errors(@content)
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
