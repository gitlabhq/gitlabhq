# frozen_string_literal: true

module Gitlab
  module Kas
    class ServerInfoPresenter
      GROUP = 'gitlab-org/cluster-integration'
      PROJECT = 'gitlab-agent'
      private_constant :GROUP, :PROJECT

      delegate :git_ref, to: :server_info, private: true
      delegate :version, to: :server_info

      def initialize
        @server_info = fetch_server_info
      end

      def retrieved_server_info?
        server_info.present?
      end

      def git_ref_for_display
        return unless git_ref.present?

        commit&.short_id || git_ref
      end

      def git_ref_url
        return unless git_ref.present?

        build_git_ref_url
      end

      private

      attr_reader :server_info

      def fetch_server_info
        Gitlab::Kas::Client.new.get_server_info
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e)
        nil
      end

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
