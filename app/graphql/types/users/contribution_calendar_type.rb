# frozen_string_literal: true

module Types
  module Users
    # rubocop: disable Graphql/AuthorizeTypes -- value object, authorized by the parent field
    class ContributionCalendarType < BaseObject
      graphql_name 'UserContributionCalendar'
      description "A user's contribution calendar: the profile page's activity heatmap for the past year."

      include TimeZoneHelper
      include Gitlab::Utils::StrongMemoize

      authorize_granular_token skip_reason: :parent_authorizes

      field :utc_offset, GraphQL::Types::Int,
        null: false,
        description: 'Offset of `timezone` from UTC, in seconds, as of the request.'

      field :timezone, GraphQL::Types::String,
        null: false,
        description: "Identifier of the timezone the days are counted in: the user's timezone, " \
          'or the instance default if the user has not set one.'

      field :days, [Types::Users::ContributionDayType],
        null: false,
        description: 'Days with at least one contribution, oldest first.'

      field :total_count, GraphQL::Types::Int,
        null: false,
        description: 'Total number of contributions in the past year.'

      # `object` is a `Gitlab::ContributionsCalendar`.

      def utc_offset
        time_zone.now.utc_offset
      end

      def timezone
        time_zone.tzinfo.identifier
      end

      def days
        activity_dates
          .map { |date, count| { date: date, count: count } }
          .sort_by { |day| day[:date] }
      end

      def total_count
        activity_dates.values.sum
      end

      private

      # Same fallback `Gitlab::ContributionsCalendar` buckets the days with, so the two fields agree.
      def time_zone
        local_timezone_instance(object.contributor.timezone)
      end

      def activity_dates
        object.activity_dates
      end
      strong_memoize_attr :activity_dates
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
