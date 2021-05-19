# frozen_string_literal: true

module Gitlab
  module RepositoryUrlBuilder
    class << self
      def build(path, protocol: :ssh)
        case protocol
        when :ssh
          ssh_url(path)
        when :http
          http_url(path)
        else
          raise NotImplementedError, "No URL builder defined for protocol #{protocol}"
        end
      end

      private

      def ssh_url(path)
        Gitlab.config.gitlab_shell.ssh_path_prefix + "#{path}.git"
      end

      def http_url(path)
        root = Gitlab::CurrentSettings.custom_http_clone_url_root.presence || Gitlab::Routing.url_helpers.root_url

        Gitlab::Utils.append_path(root, "#{path}.git")
      end
    end
  end
end
