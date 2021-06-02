# frozen_string_literal: true

module Limitable
  extend ActiveSupport::Concern
  GLOBAL_SCOPE = :limitable_global_scope

  included do
    class_attribute :limit_scope
    class_attribute :limit_relation
    class_attribute :limit_name
    class_attribute :limit_feature_flag
    self.limit_name = self.name.demodulize.tableize

    validate :validate_plan_limit_not_exceeded, on: :create
  end

  private

  def validate_plan_limit_not_exceeded
    if GLOBAL_SCOPE == limit_scope
      validate_global_plan_limit_not_exceeded
    else
      validate_scoped_plan_limit_not_exceeded
    end
  end

  def validate_scoped_plan_limit_not_exceeded
    scope_relation = self.public_send(limit_scope) # rubocop:disable GitlabSecurity/PublicSend
    return unless scope_relation
    return if limit_feature_flag && ::Feature.disabled?(limit_feature_flag, scope_relation, default_enabled: :yaml)

    relation = limit_relation ? self.public_send(limit_relation) : self.class.where(limit_scope => scope_relation) # rubocop:disable GitlabSecurity/PublicSend
    limits = scope_relation.actual_limits

    check_plan_limit_not_exceeded(limits, relation)
  end

  def validate_global_plan_limit_not_exceeded
    relation = self.class.all
    limits = Plan.default.actual_limits

    check_plan_limit_not_exceeded(limits, relation)
  end

  def check_plan_limit_not_exceeded(limits, relation)
    return unless limits.exceeded?(limit_name, relation)

    errors.add(:base, _("Maximum number of %{name} (%{count}) exceeded") %
        { name: limit_name.humanize(capitalize: false), count: limits.public_send(limit_name) }) # rubocop:disable GitlabSecurity/PublicSend
  end
end
