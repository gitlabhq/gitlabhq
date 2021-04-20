# frozen_string_literal: true

module Gitlab
  module PhabricatorImport
    class ProjectCreator
      def initialize(current_user, params)
        @current_user = current_user
        @params = params.dup
      end

      def execute
        return unless import_url.present? && api_token.present?

        project = Projects::CreateService.new(current_user, create_params).execute
        return project unless project.persisted?

        project.project_feature.update!(project_feature_attributes)

        project
      end

      private

      attr_reader :current_user, :params

      def create_params
        {
          name: project_name,
          path: project_path,
          namespace_id: namespace_id,
          import_type: 'phabricator',
          import_url: Project::UNKNOWN_IMPORT_URL,
          import_data: import_data
        }
      end

      def project_name
        params[:name]
      end

      def project_path
        params[:path]
      end

      def namespace_id
        params[:namespace_id] || current_user.namespace_id
      end

      def import_url
        params[:phabricator_server_url]
      end

      def api_token
        params[:api_token]
      end

      def project_feature_attributes
        @project_features_attributes ||=
          begin
            # everything disabled except for issues
            ProjectFeature::FEATURES.to_h do |feature|
              [ProjectFeature.access_level_attribute(feature), ProjectFeature::DISABLED]
            end.merge(ProjectFeature.access_level_attribute(:issues) => ProjectFeature::ENABLED)
          end
      end

      def import_data
        {
          data: {
            phabricator_url: import_url
          },
          credentials: {
            api_token: params.fetch(:api_token)
          }
        }
      end
    end
  end
end
