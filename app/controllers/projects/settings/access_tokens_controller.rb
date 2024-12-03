# frozen_string_literal: true

module Projects
  module Settings
    class AccessTokensController < Projects::ApplicationController
      include RenderAccessTokens
      include AccessTokensActions

      layout 'project_settings'
      feature_category :system_access

      alias_method :resource, :project

      def resource_access_tokens_path
        namespace_project_settings_access_tokens_path
      end

      private

      def represent(tokens)
        ::ProjectAccessTokenSerializer.new.represent(tokens, project: resource)
      end

      def rotate_service
        ProjectAccessTokens::RotateService
      end
    end
  end
end
