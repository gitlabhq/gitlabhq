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

      def pages_url
        return unique_url if unique_domain_enabled?

        return namespace_url if namespace_pages?

        "#{namespace_url}/#{project_path}"
      end

      def unique_host
        return unless unique_domain_enabled?
        return if config.namespace_in_path

        URI(unique_url).host
      end

      # If the project path is the same as host, we serve it as group/user page.
      #
      # e.g. For Pages external url `example.io`,
      #      `acmecorp/acmecorp.example.io` project will publish to `http(s)://acmecorp.example.io`
      # See https://docs.gitlab.com/ee/user/project/pages/getting_started_part_one.html#user-and-group-website-examples.
      def namespace_pages?
        project_path_url = "#{config.protocol}://#{project_path}".downcase

        # On development we ignore the URL port to make it work on GDK
        host_base_url(project_namespace, include_port: !Rails.env.development?) == project_path_url
      end

      def artifact_url(artifact, job)
        return unless artifact_url_available?(artifact, job)

        format(
          ARTIFACT_URL,
          host: namespace_url,
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

      def url_for(subdomain)
        if config.namespace_in_path
          URI(config.url)
            .tap { |url| url.port = config.port }
            .tap { |url| url.path = "/#{subdomain}" }
            .to_s
            .downcase
        else
          host_base_url(subdomain)
        end
      end

      def host_base_url(subdomain, include_port: true)
        URI(config.url)
          .tap { |url| url.port = include_port ? config.port : nil }
          .tap { |url| url.host.prepend("#{subdomain}.") }
          .to_s
          .downcase
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
