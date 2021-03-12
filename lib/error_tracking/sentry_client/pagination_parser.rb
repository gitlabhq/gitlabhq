# frozen_string_literal: true

module ErrorTracking
  class SentryClient
    module PaginationParser
      PATTERN = /rel=\"(?<direction>\w+)\";\sresults=\"(?<results>\w+)\";\scursor=\"(?<cursor>.+)\"/.freeze

      def self.parse(headers)
        links = headers['link'].to_s.split(',')

        links.map { |link| parse_link(link) }.compact.to_h
      end

      def self.parse_link(link)
        match = link.match(PATTERN)

        return unless match
        return if match['results'] != "true"

        [match['direction'], { 'cursor' => match['cursor'] }]
      end
      private_class_method :parse_link
    end
  end
end
