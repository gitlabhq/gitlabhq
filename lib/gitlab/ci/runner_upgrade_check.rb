# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerUpgradeCheck
      include Singleton

      def check_runner_upgrade_status(runner_version)
        runner_version = ::Gitlab::VersionInfo.parse(runner_version, parse_suffix: true)

        return { invalid_version: runner_version } unless runner_version.valid?
        return { error: runner_version } unless runner_releases_store.releases

        # Recommend update if outside of backport window
        recommended_version = recommendation_if_outside_backport_window(runner_version)
        return { recommended: recommended_version } if recommended_version

        # Recommend patch update if there's a newer release in a same minor branch as runner
        recommended_version = recommended_runner_release_update(runner_version)
        return { recommended: recommended_version } if recommended_version

        # Consider update if there's a newer release within the currently deployed GitLab version
        if available_runner_release(runner_version)
          return { available: runner_releases_store.releases_by_minor[gitlab_version.without_patch] }
        end

        { not_available: runner_version }
      end

      private

      def recommended_runner_release_update(runner_version)
        recommended_release = runner_releases_store.releases_by_minor[runner_version.without_patch]

        recommended_release if recommended_release && recommended_release > runner_version
      end

      def available_runner_release(runner_version)
        available_release = runner_releases_store.releases_by_minor[gitlab_version.without_patch]

        available_release if available_release && available_release > runner_version
      end

      def gitlab_version
        @gitlab_version ||= ::Gitlab::VersionInfo.parse(::Gitlab::VERSION)
      end

      def runner_releases_store
        RunnerReleases.instance
      end

      def recommendation_if_outside_backport_window(runner_version)
        return if runner_releases_store.releases.empty?
        return if runner_version >= runner_releases_store.releases.last # return early if runner version is too new

        minor_releases_with_index = runner_releases_store.releases_by_minor.keys.each_with_index.to_h
        runner_minor_version_index = minor_releases_with_index[runner_version.without_patch]
        if runner_minor_version_index
          # https://docs.gitlab.com/ee/policy/maintenance.html#backporting-to-older-releases
          outside_window = minor_releases_with_index.count - runner_minor_version_index > 3

          if outside_window
            recommended_release = runner_releases_store.releases_by_minor[gitlab_version.without_patch]

            recommended_release if recommended_release && recommended_release > runner_version
          end
        else
          # If unknown runner version, then recommend the latest version for the GitLab instance
          recommended_runner_release_update(gitlab_version)
        end
      end
    end
  end
end
