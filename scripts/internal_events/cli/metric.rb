# frozen_string_literal: true

module InternalEventsCli
  NEW_METRIC_FIELDS = [
    :key_path,
    :description,
    :product_group,
    :performance_indicator_type,
    :value_type,
    :status,
    :milestone,
    :introduced_by_url,
    :time_frame,
    :data_source,
    :data_category,
    :product_category,
    :distribution,
    :tier,
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

    def time_frame
      self[:time_frame] || 'all'
    end
  end

  NewMetric = Struct.new(*NEW_METRIC_FIELDS, :identifier, :actions, :key, keyword_init: true) do
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
          distribution.directory_name,
          'config',
          'metrics',
          time_frame.directory_name,
          file_name
        ].compact
      )
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

    def distribution
      Metric::Distribution.new(self[:distribution])
    end

    def key
      Metric::Key.new(self[:key] || actions, time_frame, identifier)
    end

    def events
      self[:events] || actions.map { |action| event_params(action) }
    end

    def event_params(action)
      params = { 'name' => action }
      params['unique'] = "#{identifier.value}.id" if identifier.value

      params
    end

    def actions
      self[:actions] || []
    end

    def description_prefix
      [time_frame.description, identifier.description].join(' ')
    end

    def technical_description
      simple_event_list = actions.join(' or ')

      case identifier
      when 'user'
        "#{description_prefix} who triggered #{simple_event_list}"
      when 'project', 'namespace'
        "#{description_prefix} where #{simple_event_list} occurred"
      else
        "#{description_prefix} #{simple_event_list} occurrences"
      end
    end

    def bulk_assign(key_value_pairs)
      key_value_pairs.each { |key, value| self[key] = value }
    end
  end

  class Metric
    TimeFrame = Struct.new(:value) do
      def description
        case value
        when '7d'
          'Weekly'
        when '28d'
          'Monthly'
        when 'all'
          'Total'
        end
      end

      def directory_name
        "counts_#{value}"
      end

      def key_path
        description&.downcase if value != 'all'
      end
    end

    Identifier = Struct.new(:value) do
      def description
        if value
          "count of unique #{value}s"
        else
          "count of"
        end
      end

      def key_path
        value ? "distinct_#{value}_id_from" : 'total'
      end
    end

    Distribution = Struct.new(:value) do
      def directory_name
        'ee' unless value.include?('ce')
      end
    end

    Key = Struct.new(:events, :time_frame, :identifier) do
      def value
        [
          'count',
          identifier&.key_path,
          name_for_events,
          time_frame&.key_path
        ].compact.join('_')
      end

      def full_path
        "#{prefix}.#{value}"
      end

      def name_for_events
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

    def self.parse(**args)
      ExistingMetric.new(**args)
    end

    def self.new(**args)
      NewMetric.new(**args)
    end
  end
end
