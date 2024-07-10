# frozen_string_literal: true

module Projects
  class MlController < ::Projects::ApplicationController
    feature_category :mlops

    include PreviewMarkdown

    before_action :authorize_read_model_registry!

    private

    def authorize_read_model_registry!
      render_404 unless can?(current_user, :read_model_registry, @project)
    end
  end
end
