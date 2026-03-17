# frozen_string_literal: true

module Gitlab
  module FilterEvaluator
    MAX_DEPTH = 5

    OPERATORS = {
      'eq' => ->(actual, expected) { actual == expected },
      'ne' => ->(actual, expected) { actual != expected },
      'gt' => ->(actual, expected) { actual.to_f > expected.to_f },
      'lt' => ->(actual, expected) { actual.to_f < expected.to_f },
      'contains' => ->(actual, expected) { actual.to_s.include?(expected.to_s) },
      'not_contains' => ->(actual, expected) { actual.to_s.exclude?(expected.to_s) },
      'in' => ->(actual, expected) { Array(expected).include?(actual) },
      'not_in' => ->(actual, expected) { Array(expected).exclude?(actual) }
    }.freeze

    def self.evaluate(filter, data, depth = 1)
      return true if filter.blank?
      raise ArgumentError, 'Max depth exceeded' if depth > MAX_DEPTH

      rules = Array(filter['rules'])
      match_type = filter['match'] || 'all'

      results = rules.map do |rule|
        if rule['type'] == 'group'
          evaluate(rule, data, depth + 1)
        else
          evaluate_condition(rule, data)
        end
      end

      match_type == 'all' ? results.all? : results.any?
    rescue StandardError => e
      Gitlab::AppLogger.error("Filter evaluation error: #{e.class}: #{e.message}")
      false
    end

    def self.evaluate_condition(rule, data)
      field = rule['field']

      actual = dig_value(data, field)
      expected = rule['value']
      operator = OPERATORS.fetch(rule['operator'])

      operator.call(actual, expected)
    end
    private_class_method :evaluate_condition

    def self.dig_value(hash, path)
      path.split('.').reduce(hash) do |value, key|
        value[key] || value[key.to_sym]
      end
    end
    private_class_method :dig_value
  end
end
