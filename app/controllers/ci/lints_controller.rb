module Ci
  class LintsController < ::ApplicationController
    before_action :authenticate_user!

    def show
    end

    def create
      @content = params[:content]
      @error = Gitlab::Ci::YamlProcessor.validation_message(@content)
      @status = @error.blank?

      if @error.blank?
        @config_processor = Gitlab::Ci::YamlProcessor.new(@content)
        @stages = @config_processor.stages
        @builds = @config_processor.builds
        @jobs = @config_processor.jobs
      end

      render :show
    end
  end
end
