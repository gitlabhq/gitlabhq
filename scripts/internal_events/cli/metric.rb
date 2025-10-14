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
    :events,
    :instrumentation_class
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

    # Enables comparison with new metrics
    def unique_ids
      prefix = [
        operator,
        (actions || []).sort.join('+'),
        'filter-',
        filtered?
      ].join('_')

      Array(time_frame).map { |t| prefix + t }
    end

    def operator
      events&.dig(0, 'operator') || "count(#{identifier})"
    end
  end

  NewMetric = Struct.new(*NEW_METRIC_FIELDS, :identifier, :actions, :key, :filters, :operator, keyword_init: true) do
    def formatted_output
      extra_keys = event_metric? ? { events: events } : {}

      METRIC_DEFAULTS
        .merge(to_h.compact)
        .merge(
          time_frame: assign_time_frame,
          key_path: key_path
        ).merge(extra_keys)
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
      name = event_metric? ? key.value : key_path
      "#{name}.yml"
    end

    def key_path
      event_metric? ? key.full_path : self[:key_path]
    end

    def time_frame
      Metric::TimeFrames.new(self[:time_frame])
    end

    def identifier
      Metric::Identifier.new(self[:identifier])
    end

    def key
      Metric::Key.new(self[:key] || actions, time_frame, identifier, operator)
    end

    def filters
      Metric::Filters.new(self[:filters])
    end

    def operator
      Metric::Operator.new(self[:operator])
    end

    # Enables comparison with existing metrics
    def unique_ids
      prefix = [
        operator.reference(identifier),
        actions.sort.join('+'),
        'filter-',
        filtered?
      ].join('_')

      time_frame.value.map { |t| prefix + t }
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
      params['unique'] = identifier.reference if operator.value == 'unique_count'
      params['filter'] = filter if filter&.any?
      params['operator'] = operator.reference(identifier) if operator.value == 'sum'

      params
    end

    def actions
      self[:actions] || []
    end

    # How to interpret different values for filters:
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
      [
        (time_frame.description if time_frame.single?),
        (operator.description if event_metric?),
        *(identifier.plural if identifier.default? && event_metric?)
      ].compact.join(' ').capitalize
    end

    # Provides simplified but technically accurate description
    # to be used before the user has provided a description
    def technical_description
      event_name = actions.first if events.length == 1 && !filtered?
      event_name ||= 'the selected events'
      [
        (time_frame.description if time_frame.single?),
        (operator.description if event_metric?),
        ((identifier.description % event_name).to_s if event_metric?)
      ].compact.join(' ').capitalize
    end

    def bulk_assign(key_value_pairs)
      key_value_pairs.each { |key, value| self[key] = value }
    end

    # Maintain current functionality of string time_frame for backward compatibility
    # TODO: Remove once we can deduplicate and merge metric files
    def assign_time_frame
      time_frame.single? ? time_frame.value.first : time_frame.value
    end

    def event_metric?
      data_source == 'internal_events'
    end
  end

  class Metric
    TimeFrames = Struct.new(:value) do
      def description
        (%w[all 28d 7d] & value).map do |time_trame|
          TimeFramedKeyPath::METRIC_TIME_FRAME_DESC[time_trame].capitalize
        end.join('/')
      end

      def directory_name
        return "counts_all" unless single?

        "counts_#{value.first}"
      end

      def key_path
        description&.downcase if single? && %w[7d 28d].include?(value.first)
      end

      # TODO: Delete once we are able to deduplicate and merge metric files
      def single?
        !value.is_a?(Array) || value.length == 1
      end
    end

    Identifier = Struct.new(:value) do
      # returns a description of the identifier with appropriate
      # grammar to interpolate a description of events
      def description
        if value.nil?
          "%s occurrences"
        elsif value == 'user'
          "users who triggered %s"
        elsif %w[project namespace].include?(value)
          "#{plural} where %s occurred"
        else
          "#{plural} from %s occurrences"
        end
      end

      # handles generic pluralization for unknown indentifers
      def plural
        default? ? "#{value}s" : "values for '#{value}'"
      end

      # returns a slug which can be used in the
      # metric's key_path and filepath
      def key_path(operator)
        case operator.value
        when 'unique_count'
          "distinct_#{reference.tr('.', '_')}_from"
        when 'count'
          'total'
        when 'sum'
          "#{reference.tr('.', '_')}_from"
        end
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

    Key = Struct.new(:events, :time_frame, :identifier, :operator) do
      # @param name_to_display [String] return the key with the
      #          provided name instead of a list of event names
      def value(name_to_display = nil)
        [
          operator.verb,
          identifier&.key_path(operator),
          name_to_display || name_for_events,
          time_frame&.key_path
        ].compact.join('_')
      end

      def full_path
        "#{operator.key_path}.#{value}"
      end

      private

      # Refers to the middle portion of a metric's `key_path`
      # pertaining to the relevent events; This does not include
      # identifier/time_frame/etc
      def name_for_events
        # user may have defined a different name for events
        return events unless events.respond_to?(:join)

        events.join('_and_')
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

    Operator = Struct.new(:value) do
      def description
        if qualifier
          "#{verb} of #{qualifier}"
        else
          "#{verb} of"
        end
      end

      def verb
        value == 'unique_count' ? 'count' : value
      end

      def reference(identifier)
        "#{verb}(#{identifier.value})"
      end

      def key_path
        case value
        when 'unique_count'
          'redis_hll_counters'
        when 'count'
          'counts'
        when 'sum'
          'sums'
        end
      end

      def qualifier
        case value
        when 'unique_count'
          'unique'
        when 'sum'
          'all'
        end
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
