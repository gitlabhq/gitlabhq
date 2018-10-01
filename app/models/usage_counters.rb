# frozen_string_literal: true

class UsageCounters < ActiveRecord::Base
  RECORD_LIMIT = 1.freeze
  BY = 1.freeze
  BLACKLIST_ATTRIBUTES = %w(id created_at updated_at).freeze

  validate :ensure_only_one, on: :create

  default_value_for :web_ide_commits, 0

  # This method supports concurrency so that several
  # requests are able to increment the counter without
  # us having inconsistent data
  def increment_counters(attrs)
    # We want to be able to use the service to increment
    # both a single and multiple counters
    attrs = Array(attrs)

    attrs_with_by =
      attrs.each_with_object({}) do |attr, hsh|
        hsh[attr] = BY
      end

    self.class.update_counters(id, attrs_with_by)
  end

  # Every attribute in this table except the blacklisted
  # attributes is a counter
  def totals
    attributes.except(*BLACKLIST_ATTRIBUTES).symbolize_keys
  end

  private

  # We only want one UsageCounters per instance
  def ensure_only_one
    return unless UsageCounters.count >= RECORD_LIMIT

    errors.add(:base, 'There can only be one usage counters record per instance')
  end
end
