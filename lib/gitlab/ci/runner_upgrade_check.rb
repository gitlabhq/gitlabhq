# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerUpgradeCheck
      include Singleton

      def initialize
        reset!
      end

      def check_runner_upgrade_status(runner_version)
        return :unknown unless runner_version

        releases = RunnerReleases.instance.releases
        parsed_runner_version = runner_version.is_a?(::Gitlab::VersionInfo) ? runner_version : ::Gitlab::VersionInfo.parse(runner_version)

        raise ArgumentError, "'#{runner_version}' is not a valid version" unless parsed_runner_version.valid?

        available_releases = releases.reject { |release| release > @gitlab_version }

        return :recommended if available_releases.any? { |available_release| patch_update?(available_release, parsed_runner_version) }
        return :recommended if outside_backport_window?(parsed_runner_version, releases)
        return :available if available_releases.any? { |available_release| available_release > parsed_runner_version }

        :not_available
      end

      def reset!
        @gitlab_version = ::Gitlab::VersionInfo.parse(::Gitlab::VERSION)
      end

      public_class_method :instance

      private

      def patch_update?(available_release, runner_version)
        # https://docs.gitlab.com/ee/policy/maintenance.html#patch-releases
        available_release.major == runner_version.major &&
          available_release.minor == runner_version.minor &&
          available_release.patch > runner_version.patch
      end

      def outside_backport_window?(runner_version, releases)
        return false if runner_version >= releases.last # return early if runner version is too new

        latest_minor_releases = releases.map { |r| version_without_patch(r) }.uniq { |v| v.to_s }
        latest_version_position = latest_minor_releases.count - 1
        runner_version_position = latest_minor_releases.index(version_without_patch(runner_version))

        return true if runner_version_position.nil? # consider outside if version is too old

        # https://docs.gitlab.com/ee/policy/maintenance.html#backporting-to-older-releases
        latest_version_position - runner_version_position > 2
      end

      def version_without_patch(version)
        ::Gitlab::VersionInfo.new(version.major, version.minor, 0)
      end
    end
  end
end
