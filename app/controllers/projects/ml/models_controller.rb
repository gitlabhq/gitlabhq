# frozen_string_literal: true

module Projects
  module Ml
    class ModelsController < ::Projects::ApplicationController
      before_action :check_feature_enabled
      feature_category :mlops

      def index
        @models = ::Projects::Ml::ModelFinder.new(@project).execute

        # TODO: Frontend rendering being added with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124833
        render html: ::Ml::ModelsIndexPresenter.new(@models).present
      end

      private

      def check_feature_enabled
        render_404 unless can?(current_user, :read_model_registry, @project)
      end
    end
  end
end
