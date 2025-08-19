# frozen_string_literal: true

module Packages
  module TerraformModule
    class PackagePresenter
      include Gitlab::Utils::StrongMemoize

      PIPELINE_ATTRIBUTES = %i[created_at id sha ref].freeze

      def initialize(package)
        @package = package
      end

      def as_json(options = {})
        package
          .as_json(options.merge(include: :terraform_module_metadatum))
          .merge(
            'package_files' => package_files,
            'pipelines' => pipelines(package),
            'pipeline' => pipelines(package).last
          )
      end

      private

      attr_reader :package

      def package_files
        package.installable_package_files.preload_pipelines_with_user_project_namespace_route.map do |package_file|
          package_file
            .as_json(methods: :download_path)
            .merge('pipelines' => pipelines(package_file))
        end
      end

      def pipelines(object)
        strong_memoize_with(:pipelines, object) do
          object.pipelines.map do |pipeline|
            pipeline
              .as_json(only: PIPELINE_ATTRIBUTES, include: { user: { only: :name, methods: :avatar_url } })
              .merge('project' => project_pipeline_urls(pipeline))
          end
        end
      end

      def project_pipeline_urls(pipeline)
        project = pipeline.project

        {
          'name' => project.name,
          'web_url' => ::Gitlab::Routing.url_helpers.project_url(project),
          'pipeline_url' => ::Gitlab::Routing.url_helpers.project_pipeline_url(project, pipeline),
          'commit_url' => ::Gitlab::Routing.url_helpers.project_commit_url(project, pipeline.sha)
        }
      end
    end
  end
end
