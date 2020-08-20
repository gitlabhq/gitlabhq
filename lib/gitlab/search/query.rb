# frozen_string_literal: true

module Gitlab
  module Search
    class Query < SimpleDelegator
      include EncodingHelper

      def initialize(query, filter_opts = {}, &block)
        @raw_query = query.dup
        @filters = []
        @filter_options = { default_parser: :downcase.to_proc }.merge(filter_opts)

        self.instance_eval(&block) if block_given?

        @query = Gitlab::Search::ParsedQuery.new(*extract_filters)
        # set the ParsedQuery as our default delegator thanks to SimpleDelegator
        super(@query)
      end

      private

      def filter(name, **attributes)
        filter = {
          parser: @filter_options[:default_parser],
          name: name
        }.merge(attributes)

        @filters << filter
      end

      def filter_options(**options)
        @filter_options.merge!(options)
      end

      def extract_filters
        fragments = []

        filters = @filters.each_with_object([]) do |filter, parsed_filters|
          match = @raw_query.split.find { |part| part =~ /\A-?#{filter[:name]}:/ }
          next unless match

          input = match.split(':')[1..-1].join
          next if input.empty?

          filter[:negated] = match.start_with?("-")
          filter[:value] = parse_filter(filter, input)
          filter[:regex_value] = Regexp.escape(filter[:value]).gsub('\*', '.*?')
          fragments << match

          parsed_filters << filter
        end

        query = (@raw_query.split - fragments).join(' ')

        [query, filters]
      end

      def parse_filter(filter, input)
        result = filter[:parser].call(input)

        @filter_options[:encode_binary] ? encode_binary(result) : result
      end
    end
  end
end
