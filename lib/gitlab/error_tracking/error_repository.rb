# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    # Data access layer for errors and events related to Error Tracking feature.
    class ErrorRepository
      Pagination = Struct.new(:next, :prev)

      # Generic database error
      DatabaseError = Class.new(StandardError)
      # Record was invalid
      RecordInvalidError = Class.new(DatabaseError)

      # Builds an instance of error repository backed by a strategy.
      #
      # @return [self]
      def self.build(project)
        strategy = OpenApiStrategy.new(project)

        new(strategy)
      end

      # @private
      def initialize(strategy)
        @strategy = strategy
      end

      # Stores an error and the related error event.
      #
      # @param name [String] name of the error
      # @param description [String] description of the error
      # @param actor [String] culprit (class/method/function) which triggered this error
      # @param platform [String] platform on which the error occurred
      # @param environment [String] environment on which the error occurred
      # @param level [String] severity of this error
      # @param occurred_at [Time] timestamp when the error occurred
      # @param payload [Hash] original error payload
      #
      # @return [void] nothing
      #
      # @raise [RecordInvalidError] if passed attributes were invalid to store an error or error event
      # @raise [DatabaseError] if generic error occurred
      def report_error(
        name:, description:, actor:, platform:,
        environment:, level:, occurred_at: Time.zone.now, payload: {}
      )
        strategy.report_error(
          name: name,
          description: description,
          actor: actor,
          platform: platform,
          environment: environment,
          level: level,
          occurred_at: occurred_at,
          payload: payload
        )

        nil
      end

      # Finds an error by +id+.
      #
      # @param id [Integer, String] unique error identifier
      #
      # @return [Gitlab::ErrorTracking::DetailedError] a detail error
      def find_error(id)
        strategy.find_error(id)
      end

      # Lists errors.
      #
      # @param sort [String] order list by 'first_seen', 'last_seen', or 'frequency'
      # @param filters [Hash<Symbol, String>] filter list by
      # @option filters [String] :status error status
      # @params query [String, nil] free text search
      # @param limit [Integer, String] limit result
      # @param cursor [Hash] pagination information
      #
      # @return [Array<Array<Gitlab::ErrorTracking::Error>, Pagination>]
      def list_errors(sort: 'last_seen', filters: {}, query: nil, limit: 20, cursor: {})
        limit = [limit.to_i, 100].min

        strategy.list_errors(filters: filters, query: query, sort: sort, limit: limit, cursor: cursor)
      end

      # Fetches last event for error +id+.
      #
      # @param id [Integer, String] unique error identifier
      #
      # @return [Gitlab::ErrorTracking::ErrorEvent]
      #
      # @raise [DatabaseError] if generic error occurred
      def last_event_for(id)
        strategy.last_event_for(id)
      end

      # Updates attributes of an error.
      #
      # @param id [Integer, String] unique error identifier
      # @param status [String] error status
      #
      # @return [true, false] if update was successful
      #
      # @raise [DatabaseError] if generic error occurred
      def update_error(id, status:)
        strategy.update_error(id, status: status)
      end

      def dsn_url(public_key)
        strategy.dsn_url(public_key)
      end

      private

      attr_reader :strategy
    end
  end
end
