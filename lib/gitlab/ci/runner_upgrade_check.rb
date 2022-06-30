# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerUpgradeCheck
      include Singleton

      STATUSES = {
        invalid: 'Runner version is not valid.',
        not_available: 'Upgrade is not available for the runner.',
        available: 'Upgrade is available for the runner.',
        recommended: 'Upgrade is available and recommended for the runner.'
      }.freeze

      def check_runner_upgrade_status(runner_version)
        runner_version = ::Gitlab::VersionInfo.parse(runner_version, parse_suffix: true)

        return :invalid unless runner_version.valid?

        releases = RunnerReleases.instance.releases

        # Recommend patch update if there's a newer release in a same minor branch as runner
        releases.each do |available_release|
          if available_release.same_minor_version?(runner_version) && available_release > runner_version
            return :recommended
          end
        end

        # Recommend update if outside of backport window
        if outside_backport_window?(runner_version, releases)
          return :recommended
        end

        # Consider update if there's a newer release within the currently deployed GitLab version
        releases.each do |available_release|
          if available_release.same_minor_version?(gitlab_version) && available_release > runner_version
            return :available
          end
        end

        :not_available
      end

      private

      def gitlab_version
        @gitlab_version ||= ::Gitlab::VersionInfo.parse(::Gitlab::VERSION)
      end

      def patch_update?(available_release, runner_version)
        # https://docs.gitlab.com/ee/policy/maintenance.html#patch-releases
        available_release.major == runner_version.major &&
          available_release.minor == runner_version.minor &&
          available_release.patch > runner_version.patch
      end

      def outside_backport_window?(runner_version, releases)
        return false if runner_version >= releases.last # return early if runner version is too new

        latest_minor_releases = releases.map(&:without_patch).uniq
        latest_version_position = latest_minor_releases.count - 1
        runner_version_position = latest_minor_releases.index(runner_version.without_patch)

        return true if runner_version_position.nil? # consider outside if version is too old

        # https://docs.gitlab.com/ee/policy/maintenance.html#backporting-to-older-releases
        latest_version_position - runner_version_position > 2
      end
    end
  end
end
