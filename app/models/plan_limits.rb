# frozen_string_literal: true

class PlanLimits < ApplicationRecord
  include SafelyChangeColumnDefault

  columns_changing_default :ci_max_artifact_size_lsif

  ALLOWED_LIMITS_HISTORY_ATTRIBUTES = %i[notification_limit enforcement_limit storage_size_limit
    dashboard_limit_enabled_at].freeze

  ignore_column :ci_max_artifact_size_running_container_scanning, remove_with: '14.3', remove_after: '2021-08-22'

  attribute :limits_history, ::Gitlab::Database::Type::IndifferentJsonb.new, default: -> { {} }
  validates :limits_history, json_schema: { filename: 'plan_limits_history' }

  LimitUndefinedError = Class.new(StandardError)

  belongs_to :plan

  validates :notification_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :enforcement_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def exceeded?(limit_name, subject, alternate_limit: 0)
    limit = limit_for(limit_name, alternate_limit: alternate_limit)
    return false unless limit

    case subject
    when Integer
      subject >= limit
    when ActiveRecord::Relation
      # We intentionally not accept just plain ApplicationRecord classes to
      # enforce the subject to be scoped down to a relation first.
      #
      # subject.count >= limit value is slower than checking
      # if a record exists at the limit value - 1 position.
      subject.offset(limit - 1).exists?
    else
      raise ArgumentError, "#{subject.class} is not supported as a limit value"
    end
  end

  def limit_for(limit_name, alternate_limit: 0)
    limit = read_attribute(limit_name)
    raise LimitUndefinedError, "The limit `#{limit_name}` is undefined" if limit.nil?

    alternate_limit = alternate_limit.call if alternate_limit.respond_to?(:call)

    limits = [limit, alternate_limit]
    limits.map(&:to_i).select(&:positive?).min
  end

  # Overridden in EE
  def dashboard_storage_limit_enabled?
    false
  end

  def format_limits_history(user, new_limits)
    allowed_limits = new_limits.slice(*ALLOWED_LIMITS_HISTORY_ATTRIBUTES)
    return {} if allowed_limits.empty?

    allowed_limits.each do |attribute, value|
      next if value == self[attribute]

      limits_history[attribute] ||= []
      limits_history[attribute] << {
        "user_id" => user.id,
        "username" => user.username,
        "timestamp" => Time.current.utc.to_i,
        "value" => value
      }
    end

    limits_history
  end
end

PlanLimits.prepend_mod_with('PlanLimits')
