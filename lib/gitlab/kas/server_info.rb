# frozen_string_literal: true

module Gitlab
  module Kas
    class ServerInfo
      include Presentable

      delegate :git_ref, :version, to: :fetched_server_info

      def initialize
        @fetched_server_info = fetch_server_info
      end

      def retrieved_server_info?
        fetched_server_info.present?
      end

      def version_info
        return unless retrieved_server_info? && version.present?
        return Gitlab::VersionInfo.parse("#{version}+#{git_ref}", parse_suffix: true) if valid_commit_ref?

        Gitlab::VersionInfo.parse(version)
      end

      def valid_commit_ref?
        return unless retrieved_server_info?

        ::Gitlab::Git::Commit.valid?(git_ref) &&
          git_ref.match?(::Gitlab::Git::COMMIT_ID)
      end

      private

      attr_reader :fetched_server_info

      def fetch_server_info
        Gitlab::Kas::Client.new.get_server_info
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e)
        nil
      end
    end
  end
end
