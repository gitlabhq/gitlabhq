# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerUpgradeCheck
      def initialize(gitlab_version, runner_releases_store = nil)
        @gitlab_version = ::Gitlab::VersionInfo.parse(gitlab_version, parse_suffix: true)
        @releases_store = runner_releases_store
      end

      def check_runner_upgrade_suggestion(runner_version)
        check_runner_upgrade_suggestions(runner_version).first
      end

      private

      def runner_releases_store
        @releases_store ||= RunnerReleases.instance
      end

      def add_suggestion(suggestions, runner_version, version, status)
        return false unless version && version > runner_version

        suggestions[version] = status
        true
      end

      def check_runner_upgrade_suggestions(runner_version)
        runner_version = ::Gitlab::VersionInfo.parse(runner_version, parse_suffix: true)

        return { runner_version => :invalid_version } unless runner_version.valid?
        return { runner_version => :error } unless runner_releases_store.releases

        suggestions = {}

        # Recommend update if outside of backport window
        unless add_recommendation_if_outside_backport_window(runner_version, suggestions)
          # Recommend patch update if there's a newer release in a same minor branch as runner
          add_recommended_runner_release_update(runner_version, suggestions)
        end

        # Consider update if there's a newer release within the currently deployed GitLab version
        add_available_runner_release(runner_version, suggestions)

        suggestions[runner_version] = :unavailable if suggestions.empty?

        suggestions
      end

      def add_recommended_runner_release_update(runner_version, suggestions)
        recommended_release = runner_releases_store.releases_by_minor[runner_version.without_patch]
        return true if add_suggestion(suggestions, runner_version, recommended_release, :recommended)

        # Consider the edge case of pre-release runner versions that get registered, but are never published.
        # In this case, suggest the latest compatible runner version
        latest_release = runner_releases_store.releases_by_minor.values.select { |v| v < @gitlab_version }.max
        add_suggestion(suggestions, runner_version, latest_release, :recommended)
      end

      def add_available_runner_release(runner_version, suggestions)
        available_version = runner_releases_store.releases_by_minor[@gitlab_version.without_patch]
        unless suggestions.include?(available_version)
          add_suggestion(suggestions, runner_version, available_version, :available)
        end
      end

      def add_recommendation_if_outside_backport_window(runner_version, suggestions)
        return false if runner_releases_store.releases.empty?
        return false if runner_version >= runner_releases_store.releases.last # return early if runner version is too new

        minor_releases_with_index = runner_releases_store.releases_by_minor.keys.each_with_index.to_h
        runner_minor_version_index = minor_releases_with_index[runner_version.without_patch]
        if runner_minor_version_index
          # https://docs.gitlab.com/ee/policy/maintenance.html#backporting-to-older-releases
          outside_window = minor_releases_with_index.count - runner_minor_version_index > 3

          if outside_window
            recommended_version = runner_releases_store.releases_by_minor[@gitlab_version.without_patch]
            return add_suggestion(suggestions, runner_version, recommended_version, :recommended)
          end
        else
          # If unknown runner version, then recommend the latest version for the GitLab instance
          return add_recommended_runner_release_update(@gitlab_version, suggestions)
        end

        false
      end
    end
  end
end
