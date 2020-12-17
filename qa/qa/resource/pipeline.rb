# frozen_string_literal: true

module QA
  module Resource
    class Pipeline < Base
      attribute :project do
        Resource::Project.fabricate! do |project|
          project.name = 'project-with-pipeline'
        end
      end

      attribute :id
      attribute :status
      attribute :ref
      attribute :sha

      # array in form
      # [
      #   { key: 'UPLOAD_TO_S3', variable_type: 'file', value: true },
      #   { key: 'SOMETHING', variable_type: 'env_var', value: 'yes' }
      # ]
      attribute :variables

      def initialize
        @variables = []
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)
        Page::Project::Pipeline::New.perform(&:click_run_pipeline_button)
      end

      def ref
        project.default_branch
      end

      def api_get_path
        "/projects/#{project.id}/pipelines/#{id}"
      end

      def api_post_path
        "/projects/#{project.id}/pipeline"
      end

      def api_post_body
        {
          ref: ref,
          variables: variables
        }
      end
    end
  end
end
