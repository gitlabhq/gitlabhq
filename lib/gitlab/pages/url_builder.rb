# frozen_string_literal: true

module Gitlab
  module Pages
    class UrlBuilder
      attr_reader :project_namespace

      ALLOWED_ARTIFACT_EXTENSIONS = %w[.html .htm .txt .json .xml .log].freeze
      ARTIFACT_URL = "%{host}/-/%{project_path}/-/jobs/%{job_id}/artifacts/%{artifact_path}"

      def initialize(project)
        @project = project
        @project_namespace, _, @project_path = project.full_path.partition('/')
      end

      def pages_url(with_unique_domain: false)
        return unique_url if with_unique_domain && unique_domain_enabled?

        return "#{pages_base_url}/#{project_namespace}/#{project_path}".downcase if config.namespace_in_path

        project_path_url = "#{config.protocol}://#{project_path}".downcase

        # If the project path is the same as host, we serve it as group page
        # On development we ignore the URL port to make it work on GDK
        return namespace_url if Rails.env.development? && portless(namespace_url) == project_path_url
        # If the project path is the same as host, we serve it as group page
        return namespace_url if namespace_url == project_path_url

        "#{namespace_url}/#{project_path}"
      end

      def unique_host
        return unless unique_domain_enabled?

        URI(unique_url).host
      end

      def namespace_pages?
        namespace_url == pages_url
      end

      def artifact_url(artifact, job)
        return unless artifact_url_available?(artifact, job)

        host_url = config.namespace_in_path ? "#{pages_base_url}/#{project_namespace}" : namespace_url

        format(
          ARTIFACT_URL,
          host: host_url,
          project_path: project_path,
          job_id: job.id,
          artifact_path: artifact.path)
      end

      def artifact_url_available?(artifact, job)
        config.enabled &&
          config.artifacts_server &&
          ALLOWED_ARTIFACT_EXTENSIONS.include?(File.extname(artifact.name)) &&
          (config.access_control || job.project.public?)
      end

      private

      attr_reader :project, :project_path

      def namespace_url
        @namespace_url ||= url_for(project_namespace)
      end

      def unique_url
        @unique_url ||= url_for(project.project_setting.pages_unique_domain)
      end

      def pages_base_url
        @pages_url ||= URI(config.url)
                         .tap { |url| url.port = config.port }
                         .to_s
                         .downcase
      end

      def url_for(subdomain)
        URI(config.url)
          .tap { |url| url.port = config.port }
          .tap { |url| url.host.prepend("#{subdomain}.") }
          .to_s
          .downcase
      end

      def portless(url)
        URI(url)
          .tap { |u| u.port = nil }
          .to_s
      end

      def unique_domain_enabled?
        project.project_setting.pages_unique_domain_enabled?
      end

      def config
        Gitlab.config.pages
      end
    end
  end
end
