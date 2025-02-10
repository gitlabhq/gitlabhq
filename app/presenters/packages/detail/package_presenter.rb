# frozen_string_literal: true

module Packages
  module Detail
    class PackagePresenter
      def initialize(package)
        @package = package
      end

      def detail_view
        name = @package.name
        name = @package.conan_recipe if @package.conan?

        package_detail = {
          id: @package.id,
          created_at: @package.created_at,
          name: name,
          package_files: package_file_views,
          package_type: @package.package_type,
          status: @package.status,
          project_id: @package.project_id,
          tags: @package.tags.as_json,
          updated_at: @package.updated_at,
          version: @package.version
        }

        package_detail[:conan_package_name] = @package.name if @package.conan?
        package_detail[:maven_metadatum] = @package.maven_metadatum if @package.try(:maven_metadatum)
        package_detail[:nuget_metadatum] = @package.nuget_metadatum if @package.try(:nuget_metadatum)
        package_detail[:composer_metadatum] = @package.composer_metadatum if @package.try(:composer_metadatum)
        package_detail[:conan_metadatum] = @package.conan_metadatum if @package.conan? && @package.conan_metadatum
        if @package.terraform_module? && @package.terraform_module_metadatum
          package_detail[:terraform_module_metadatum] = @package.terraform_module_metadatum
        end

        package_detail[:dependency_links] = @package.dependency_links.map { |link| build_dependency_links(link) }
        package_detail[:pipeline] = build_pipeline_info(@package.pipeline) if @package.pipeline
        package_detail[:pipelines] = build_pipeline_infos(@package.pipelines) if @package.pipelines.present?

        package_detail
      end

      private

      def package_file_views
        package_files = @package.installable_package_files

        package_files.map { |pf| build_package_file_view(pf) }
      end

      def build_package_file_view(package_file)
        file_view = {
          created_at: package_file.created_at,
          download_path: package_file.download_path,
          file_name: package_file.file_name,
          size: package_file.size,
          file_md5: package_file.file_md5,
          file_sha1: package_file.file_sha1,
          file_sha256: package_file.file_sha256,
          id: package_file.id
        }

        file_view[:pipelines] = build_pipeline_infos(package_file.pipelines) if package_file.pipelines.present?

        file_view
      end

      def build_pipeline_infos(pipeline_infos)
        pipeline_infos.map { |pipeline_info| build_pipeline_info(pipeline_info) }
      end

      def build_pipeline_info(pipeline_info)
        {
          created_at: pipeline_info.created_at,
          id: pipeline_info.id,
          sha: pipeline_info.sha,
          ref: pipeline_info.ref,
          user: build_user_info(pipeline_info.user),
          project: {
            name: pipeline_info.project.name,
            web_url: pipeline_info.project.web_url,
            pipeline_url: Gitlab::Routing.url_helpers.project_pipeline_url(pipeline_info.project, pipeline_info),
            commit_url: Gitlab::Routing.url_helpers.project_commit_url(pipeline_info.project, pipeline_info.sha)
          }
        }
      end

      def build_user_info(user)
        return unless user

        {
          avatar_url: user.avatar_url,
          name: user.name
        }
      end

      def build_dependency_links(link)
        {
          name: link.dependency.name,
          version_pattern: link.dependency.version_pattern,
          target_framework: link.nuget_metadatum&.target_framework
        }.compact
      end
    end
  end
end
