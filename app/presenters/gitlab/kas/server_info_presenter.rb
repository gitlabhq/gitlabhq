# frozen_string_literal: true

module Gitlab
  module Kas
    class ServerInfoPresenter < Gitlab::View::Presenter::Delegated
      presents ::Gitlab::Kas::ServerInfo, as: :server_info

      GROUP = 'gitlab-org/cluster-integration'
      PROJECT = 'gitlab-agent'
      private_constant :GROUP, :PROJECT

      def git_ref_for_display
        return unless retrieved_server_info? && git_ref.present?

        commit&.short_id || git_ref
      end

      def git_ref_url
        return unless retrieved_server_info? && git_ref.present?

        build_git_ref_url
      end

      private

      def build_git_ref_url
        Gitlab::Utils.append_path(Gitlab::Saas.com_url, git_ref_path)
      end

      def commit
        return unless valid_commit_ref?

        ::Gitlab::Git::Commit.new(nil, { id: git_ref })
      end

      def valid_commit_ref?
        ::Gitlab::Git::Commit.valid?(git_ref) &&
          git_ref.match?(::Gitlab::Git::COMMIT_ID)
      end

      def tag
        git_ref if valid_version_tag?
      end

      def valid_version_tag?
        Gitlab::VersionInfo.parse(git_ref).valid?
      end

      def git_ref_path
        if commit
          build_commit_path
        elsif tag
          build_tag_path
        end
      end

      def build_commit_path
        url_helpers.namespace_project_commits_path(GROUP, PROJECT, git_ref)
      end

      def build_tag_path
        url_helpers.namespace_project_tag_path(GROUP, PROJECT, git_ref)
      end

      def url_helpers
        Rails.application.routes.url_helpers
      end
    end
  end
end
