# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class DefaultNamespace
      attr_reader :cluster, :project

      delegate :platform_kubernetes, to: :cluster

      ##
      # Ideally we would just use an environment record here instead of
      # passing a project and name/slug separately, but we need to be able
      # to look up namespaces before the environment has been persisted.
      def initialize(cluster, project:)
        @cluster = cluster
        @project = project
      end

      def from_environment_name(name)
        from_environment_slug(generate_slug(name))
      end

      def from_environment_slug(slug)
        default_platform_namespace(slug) || default_project_namespace(slug)
      end

      private

      def default_platform_namespace(slug)
        return unless platform_kubernetes&.namespace.present?

        if cluster.managed? && cluster.namespace_per_environment?
          "#{platform_kubernetes.namespace}-#{slug}"
        else
          platform_kubernetes.namespace
        end
      end

      def default_project_namespace(environment_slug)
        maybe_environment_suffix = cluster.namespace_per_environment? ? "-#{environment_slug}" : ''
        suffix = "-#{project.id}#{maybe_environment_suffix}"
        namespace = project_path_slug(63 - suffix.length) + suffix
        Gitlab::NamespaceSanitizer.sanitize(namespace)
      end

      def project_path_slug(max_length)
        Gitlab::NamespaceSanitizer
          .sanitize(project.path.downcase)
          .first(max_length)
      end

      ##
      # Environment slug can be predicted given an environment
      # name, so even if the environment isn't persisted yet we
      # still know what to look for.
      def generate_slug(name)
        Gitlab::Slug::Environment.new(name).generate
      end
    end
  end
end
