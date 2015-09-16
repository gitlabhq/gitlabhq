module Ci
  class LintsController < Ci::ApplicationController
    before_action :authenticate_user!

    def show
    end

    def create
      if params[:content].blank?
        @status = false
        @error = "Please provide content of .gitlab-ci.yml"
      else
        @config_processor = Ci::GitlabCiYamlProcessor.new params[:content]
        @stages = @config_processor.stages
        @builds = @config_processor.builds
        @status = true
      end
    rescue Ci::GitlabCiYamlProcessor::ValidationError => e
      @error = e.message
      @status = false
    rescue Exception => e
      @error = "Undefined error"
      @status = false
    end
  end
end
