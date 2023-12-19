# frozen_string_literal: true

module Projects
  module Gcp
    module ArtifactRegistry
      class BaseController < ::Projects::ApplicationController
        before_action :ensure_feature_flag
        before_action :ensure_saas
        before_action :authorize_read_container_image!
        before_action :ensure_private_project

        feature_category :container_registry
        urgency :low

        private

        def ensure_feature_flag
          return if Feature.enabled?(:gcp_technical_demo, project)

          @error = 'Feature flag disabled'

          render
        end

        def ensure_saas
          return if Gitlab.com_except_jh? # rubocop: disable Gitlab/AvoidGitlabInstanceChecks -- demo requirement

          @error = "Can't run here"

          render
        end

        def ensure_private_project
          return if project.private?

          @error = 'Can only run on private projects'

          render
        end
      end
    end
  end
end
