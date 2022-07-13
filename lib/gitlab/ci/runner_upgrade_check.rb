# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerUpgradeCheck
      include Singleton

      def check_runner_upgrade_status(runner_version)
        runner_version = ::Gitlab::VersionInfo.parse(runner_version, parse_suffix: true)

        return :invalid_version unless runner_version.valid?
        return :error unless runner_releases_store.releases

        # Recommend patch update if there's a newer release in a same minor branch as runner
        return :recommended if runner_release_update_recommended?(runner_version)

        # Recommend update if outside of backport window
        return :recommended if outside_backport_window?(runner_version)

        # Consider update if there's a newer release within the currently deployed GitLab version
        return :available if runner_release_available?(runner_version)

        :not_available
      end

      private

      def runner_release_update_recommended?(runner_version)
        recommended_release = runner_releases_store.releases_by_minor[runner_version.without_patch]

        recommended_release && recommended_release > runner_version
      end

      def runner_release_available?(runner_version)
        available_release = runner_releases_store.releases_by_minor[gitlab_version.without_patch]

        available_release && available_release > runner_version
      end

      def gitlab_version
        @gitlab_version ||= ::Gitlab::VersionInfo.parse(::Gitlab::VERSION)
      end

      def runner_releases_store
        RunnerReleases.instance
      end

      def outside_backport_window?(runner_version)
        return false if runner_releases_store.releases.empty?
        return false if runner_version >= runner_releases_store.releases.last # return early if runner version is too new

        minor_releases_with_index = runner_releases_store.releases_by_minor.keys.each_with_index.to_h
        runner_minor_version_index = minor_releases_with_index[runner_version.without_patch]
        return true if runner_minor_version_index.nil?

        # https://docs.gitlab.com/ee/policy/maintenance.html#backporting-to-older-releases
        minor_releases_with_index.count - runner_minor_version_index > 3
      end
    end
  end
end
