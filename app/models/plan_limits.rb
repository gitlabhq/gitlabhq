# frozen_string_literal: true

class PlanLimits < ApplicationRecord
  include IgnorableColumns

  ignore_column :ci_max_artifact_size_running_container_scanning, remove_with: '14.3', remove_after: '2021-08-22'

  LimitUndefinedError = Class.new(StandardError)

  belongs_to :plan

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
end
