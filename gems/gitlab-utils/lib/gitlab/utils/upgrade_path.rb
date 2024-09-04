# frozen_string_literal: true

module Gitlab
  module Utils
    class UpgradePath
      SCHEDULED_STOPS = [2, 5, 8, 11].freeze
      attr_reader :upgrade_path, :version_info

      def initialize(upgrade_path, version_info)
        @upgrade_path = upgrade_path
        @version_info = version_info
      end

      def last_required_stop
        all_stops.select do |stop|
          stop < version_info.without_patch
        end.max
      end

      def next_required_stop
        all_stops.select do |stop|
          stop >= version_info.without_patch
        end.min
      end

      def required_stop?
        all_stops.include? version_info.without_patch
      end

      private

      # We want this to return a list of scheduled stops for the current major version, and the first
      # stop in the next major version.
      def scheduled_stops
        current_version_stops = SCHEDULED_STOPS.map do |minor|
          Gitlab::VersionInfo.new(version_info.major, minor)
        end
        next_version_first_stop = [Gitlab::VersionInfo.new(version_info.major + 1, SCHEDULED_STOPS.first)]

        current_version_stops + next_version_first_stop
      end

      def recorded_stops
        upgrade_path.map do |stop|
          Gitlab::VersionInfo.new(stop["major"], stop["minor"])
        end
      end

      def all_stops
        (recorded_stops + scheduled_stops).uniq.sort
      end
    end
  end
end
