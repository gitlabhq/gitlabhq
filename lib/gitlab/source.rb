# frozen_string_literal: true

module Gitlab
  class Source # rubocop:disable Gitlab/NamespacedClass
    class << self
      def ref
        return Gitlab.revision if Gitlab.pre_release?

        "v#{Gitlab::VERSION}"
      end

      def release_url
        path = if Gitlab.pre_release?
                 url_helpers.namespace_project_commits_path(group, project, ref)
               else
                 url_helpers.namespace_project_tag_path(group, project, ref)
               end

        Gitlab::Utils.append_path(host_url, path)
      end

      private

      def host_url
        Gitlab::Saas.com_url
      end

      def group
        'gitlab-org'
      end

      def project
        'gitlab-foss'
      end

      def url_helpers
        Rails.application.routes.url_helpers
      end
    end
  end
end

Gitlab::Source.prepend_mod
