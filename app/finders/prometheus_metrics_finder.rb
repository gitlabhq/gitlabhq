# frozen_string_literal: true

class PrometheusMetricsFinder
  ACCEPTED_PARAMS = [
    :project,
    :group,
    :title,
    :y_label,
    :identifier,
    :id,
    :common,
    :ordered
  ].freeze

  # Cautiously preferring a memoized class method over a constant
  # so that the DB connection is accessed after the class is loaded.
  def self.indexes
    @indexes ||= PrometheusMetric
      .connection
      .indexes(:prometheus_metrics)
      .map { |index| index.columns.map(&:to_sym) }
  end

  def initialize(params = {})
    @params = params.slice(*ACCEPTED_PARAMS)
  end

  # @return [PrometheusMetric, PrometheusMetric::ActiveRecord_Relation]
  def execute
    validate_params!

    metrics = by_project(::PrometheusMetric.all)
    metrics = by_group(metrics)
    metrics = by_title(metrics)
    metrics = by_y_label(metrics)
    metrics = by_common(metrics)
    metrics = by_ordered(metrics)
    metrics = by_identifier(metrics)
    by_id(metrics)
  end

  private

  attr_reader :params

  def by_project(metrics)
    return metrics unless params[:project]

    metrics.for_project(params[:project])
  end

  def by_group(metrics)
    return metrics unless params[:group]

    metrics.for_group(params[:group])
  end

  def by_title(metrics)
    return metrics unless params[:title]

    metrics.for_title(params[:title])
  end

  def by_y_label(metrics)
    return metrics unless params[:y_label]

    metrics.for_y_label(params[:y_label])
  end

  def by_common(metrics)
    return metrics unless params[:common]

    metrics.common
  end

  def by_ordered(metrics)
    return metrics unless params[:ordered]

    metrics.ordered
  end

  def by_identifier(metrics)
    return metrics unless params[:identifier]

    metrics.for_identifier(params[:identifier])
  end

  def by_id(metrics)
    return metrics unless params[:id]

    metrics.id_in(params[:id])
  end

  def validate_params!
    validate_params_present!
    validate_id_params!
    validate_indexes!
  end

  # Ensure all provided params are supported
  def validate_params_present!
    raise ArgumentError, "Please provide one or more of: #{ACCEPTED_PARAMS}" if params.blank?
  end

  # Protect against the caller "finding" the wrong metric
  def validate_id_params!
    raise ArgumentError, 'Only one of :identifier, :id is permitted' if params[:identifier] && params[:id]
    raise ArgumentError, ':identifier must be scoped to a :project or :common' if params[:identifier] && !(params[:project] || params[:common])
  end

  # Protect against unaccounted-for, complex/slow queries.
  # This is not a hard and fast rule, but is meant to encourage
  # mindful inclusion of new queries.
  def validate_indexes!
    indexable_params = params.except(:ordered, :id, :project).keys
    indexable_params << :project_id if params[:project]
    indexable_params.sort!

    raise ArgumentError, "An index should exist for params: #{indexable_params}" unless appropriate_index?(indexable_params)
  end

  def appropriate_index?(indexable_params)
    return true if indexable_params.blank?

    self.class.indexes.any? { |index| (index - indexable_params).empty? }
  end
end
