# frozen_string_literal: true

module InternalEventsCli
  NEW_METRIC_FIELDS = [
    :key_path,
    :description,
    :product_section,
    :product_stage,
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

  METRIC_DEFAULTS = {
    product_section: nil,
    product_stage: nil,
    product_group: nil,
    introduced_by_url: 'TODO',
    value_type: 'number',
    status: 'active',
    data_source: 'internal_events',
    data_category: 'optional',
    performance_indicator_type: []
  }.freeze

  Metric = Struct.new(*NEW_METRIC_FIELDS, *ADDITIONAL_METRIC_FIELDS, :identifier, :actions, keyword_init: true) do
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
          ('ee' unless distribution.include?('ce')),
          'config',
          'metrics',
          "counts_#{time_frame}",
          "#{key}.yml"
        ].compact
      )
    end

    def key
      [
        'count',
        (identifier ? "distinct_#{identifier}_id_from" : 'total'),
        actions.join('_and_'),
        (time_frame_prefix&.downcase if time_frame != 'all')
      ].compact.join('_')
    end

    def key_path
      self[:key_path] ||= "#{key_path_prefix}.#{key}"
    end

    def events
      self[:events] ||= actions.map do |action|
        if identifier
          {
            'name' => action,
            'unique' => "#{identifier}.id"
          }
        else
          { 'name' => action }
        end
      end
    end

    def key_path_prefix
      if identifier
        'redis_hll_counters'
      else
        'counts'
      end
    end

    def actions
      self[:actions] || []
    end

    def identifier_prefix
      if identifier
        "count of unique #{identifier}s"
      else
        "count of"
      end
    end

    def time_frame_prefix
      case time_frame
      when '7d'
        'Weekly'
      when '28d'
        'Monthly'
      when 'all'
        'Total'
      end
    end

    def prefix
      [time_frame_prefix, identifier_prefix].join(' ')
    end

    def technical_description
      simple_event_list = actions.join(' or ')

      case identifier
      when 'user'
        "#{prefix} who triggered #{simple_event_list}"
      when 'project', 'namespace'
        "#{prefix} where #{simple_event_list} occurred"
      else
        "#{prefix} #{simple_event_list} occurrences"
      end
    end

    def bulk_assign(key_value_pairs)
      key_value_pairs.each { |key, value| self[key] = value }
    end
  end
end
