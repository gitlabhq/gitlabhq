# frozen_string_literal: true

module InternalEventsCli
  NEW_METRIC_FIELDS = [
    :key_path,
    :description,
    :product_group,
    :product_categories,
    :performance_indicator_type,
    :value_type,
    :status,
    :milestone,
    :introduced_by_url,
    :time_frame,
    :data_source,
    :data_category,
    :tiers,
    :events
  ].freeze

  ADDITIONAL_METRIC_FIELDS = [
    :milestone_removed,
    :removed_by_url,
    :removed_by,
    :repair_issue_url,
    :value_json_schema,
    :name
  ].freeze

  # These keys will always be included in the definition yaml
  METRIC_DEFAULTS = {
    product_group: nil,
    introduced_by_url: 'TODO',
    value_type: 'number',
    status: 'active',
    data_source: 'internal_events',
    data_category: 'optional',
    performance_indicator_type: []
  }.freeze

  ExistingMetric = Struct.new(*NEW_METRIC_FIELDS, *ADDITIONAL_METRIC_FIELDS, :file_path, keyword_init: true) do
    def identifier
      events&.dig(0, 'unique')&.chomp('.id')
    end

    def actions
      events&.map { |event| event['name'] } # rubocop:disable Rails/Pluck -- not rails
    end

    def filters
      events&.map do |event|
        [event['name'], event['filter'] || {}]
      end
    end

    def filtered?
      !!filters&.any? { |(_action, filter)| filter&.any? }
    end

    def time_frame
      self[:time_frame] || 'all'
    end
  end

  NewMetric = Struct.new(*NEW_METRIC_FIELDS, :identifier, :actions, :key, :filters, keyword_init: true) do
    def formatted_output
      METRIC_DEFAULTS
        .merge(to_h.compact)
        .merge(
          key_path: key_path,
          events: events)
        .slice(*NEW_METRIC_FIELDS)
        .transform_keys(&:to_s)
        .to_yaml(line_width: 150)
    end

    def file_path
      File.join(
        *[
          distribution_path,
          'config',
          'metrics',
          time_frame.directory_name,
          file_name
        ].compact
      )
    end

    def distribution_path
      'ee' unless tiers.include?('free')
    end

    def file_name
      "#{key.value}.yml"
    end

    def key_path
      key.full_path
    end

    def time_frame
      Metric::TimeFrame.new(self[:time_frame])
    end

    def identifier
      Metric::Identifier.new(self[:identifier])
    end

    def key
      Metric::Key.new(self[:key] || actions, time_frame, identifier)
    end

    def filters
      Metric::Filters.new(self[:filters])
    end

    # Returns value for the `events` key in the metric definition.
    # Requires #actions or #filters to be set by the caller first.
    #
    # @return [Hash]
    def events
      if filters.assigned?
        self[:filters].map { |(action, filter)| event_params(action, filter) }
      else
        actions.map { |action| event_params(action) }
      end
    end

    def event_params(action, filter = nil)
      params = { 'name' => action }
      params['unique'] = identifier.reference if identifier.value
      params['filter'] = filter if filter&.any?

      params
    end

    def actions
      self[:actions] || []
    end

    # How to interpretting different values for filters:
    # nil --> not expected, assigned or filtered
    #        (metric not initialized with filters)
    # [] --> both expected and filtered
    #        (metric initialized with filters, but not yet assigned by user)
    # [['event', {}]] --> not expected, assigned or filtered
    #        (filters were expected, but then skipped by user)
    # [['event', { 'label' => 'a' }]] --> both assigned and filtered
    #        (filters exist for any event; user is done assigning)
    def filtered?
      filters.assigned? || filters.expected?
    end

    def filters_expected?
      filters.expected?
    end

    # Automatically prepended to all new descriptions
    # ex) Total count of
    # ex) Weekly/Monthly count of unique
    # ex) Count of
    def description_prefix
      description_components = [
        time_frame.description,
        identifier.prefix,
        *(identifier.plural if identifier.default?)
      ].compact

      description_components.join(' ').capitalize
    end

    # Provides simplified but technically accurate description
    # to be used before the user has provided a description
    def technical_description
      event_name = actions.first if events.length == 1 && !filtered?
      event_name ||= 'the selected events'
      [
        time_frame.description,
        (identifier.description % event_name).to_s
      ].compact.join(' ').capitalize
    end

    def bulk_assign(key_value_pairs)
      key_value_pairs.each { |key, value| self[key] = value }
    end
  end

  class Metric
    TimeFrame = Struct.new(:value) do
      def description
        case value
        when Array
          nil # array time_frame metrics have no description prefix
        when '7d'
          'weekly'
        when '28d'
          'monthly'
        when 'all'
          'total'
        end
      end

      def directory_name
        return "counts_all" if value.is_a? Array

        "counts_#{value}"
      end

      def key_path
        description&.downcase if %w[7d 28d].include?(value)
      end
    end

    Identifier = Struct.new(:value) do
      # returns a description of the identifier with appropriate
      # grammer to interpolate a description of events
      def description
        if value.nil?
          "#{prefix} %s occurrences"
        elsif value == 'user'
          "#{prefix} users who triggered %s"
        elsif %w[project namespace].include?(value)
          "#{prefix} #{plural} where %s occurred"
        else
          "#{prefix} #{plural} from %s occurrences"
        end
      end

      # handles generic pluralization for unknown indentifers
      def plural
        default? ? "#{value}s" : "values for '#{value}'"
      end

      def prefix
        if value
          "count of unique"
        else
          "count of"
        end
      end

      # returns a slug which can be used in the
      # metric's key_path and filepath
      def key_path
        value ? "distinct_#{reference.tr('.', '_')}_from" : 'total'
      end

      # Returns the identifier string that will be included in the yml
      def reference
        default? ? "#{value}.id" : value
      end

      # Refers to the top-level identifiers not included in
      # additional_properties
      def default?
        %w[user project namespace].include?(value)
      end
    end

    Key = Struct.new(:events, :time_frame, :identifier) do
      # @param name_to_display [String] return the key with the
      #          provided name instead of a list of event names
      def value(name_to_display = nil)
        [
          'count',
          identifier&.key_path,
          name_to_display || name_for_events,
          time_frame&.key_path
        ].compact.join('_')
      end

      def full_path
        "#{prefix}.#{value}"
      end

      # Refers to the middle portion of a metric's `key_path`
      # pertaining to the relevent events; This does not include
      # identifier/time_frame/etc
      def name_for_events
        # user may have defined a different name for events
        return events unless events.respond_to?(:join)

        events.join('_and_')
      end

      def prefix
        if identifier.value
          'redis_hll_counters'
        else
          'counts'
        end
      end
    end

    Filters = Struct.new(:filters) do
      def expected?
        filters == []
      end

      def assigned?
        !!filters&.any? { |(_action, filter)| filter.any? }
      end

      def descriptions
        Array(filters).filter_map do |(action, filter)|
          next action if filter.none?

          "#{action}(#{describe_filter(filter)})"
        end.sort_by(&:length)
      end

      def describe_filter(filter)
        filter.map { |k, v| "#{k}=#{v}" }.join(',')
      end
    end

    def self.parse(**args)
      ExistingMetric.new(**args)
    end

    def self.new(**args)
      NewMetric.new(**args)
    end
  end
end
