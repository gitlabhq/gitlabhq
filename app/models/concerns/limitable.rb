# frozen_string_literal: true

module Limitable
  extend ActiveSupport::Concern
  GLOBAL_SCOPE = :limitable_global_scope

  included do
    class_attribute :limit_scope
    class_attribute :limit_relation
    class_attribute :limit_name
    class_attribute :limit_feature_flag
    class_attribute :limit_feature_flag_for_override # Allows selectively disabling by actor (as per https://docs.gitlab.com/ee/development/feature_flags/#selectively-disable-by-actor)
    self.limit_name = self.name.demodulize.tableize

    validate :validate_plan_limit_not_exceeded, on: :create
  end

  def exceeds_limits?
    limits, relation = fetch_plan_limit_data

    limits&.exceeded?(limit_name, relation)
  end

  private

  def validate_plan_limit_not_exceeded
    limits, relation = fetch_plan_limit_data

    check_plan_limit_not_exceeded(limits, relation)
  end

  def fetch_plan_limit_data
    if GLOBAL_SCOPE == limit_scope
      global_plan_limits
    else
      scoped_plan_limits
    end
  end

  def scoped_plan_limits
    scope_relation = self.public_send(limit_scope) # rubocop:disable GitlabSecurity/PublicSend
    return unless scope_relation
    return if limit_feature_flag && ::Feature.disabled?(limit_feature_flag, scope_relation, type: :undefined)

    return if limit_feature_flag_for_override &&
      ::Feature.enabled?(limit_feature_flag_for_override, scope_relation, type: :undefined)

    relation = limit_relation ? self.public_send(limit_relation) : self.class.where(limit_scope => scope_relation) # rubocop:disable GitlabSecurity/PublicSend
    limits = scope_relation.actual_limits

    [limits, relation]
  end

  def global_plan_limits
    relation = self.class.all
    limits = Plan.default.actual_limits

    [limits, relation]
  end

  def check_plan_limit_not_exceeded(limits, relation)
    return unless limits&.exceeded?(limit_name, relation)

    errors.add(
      :base,
      _("Maximum number of %{name} (%{count}) exceeded") %
        { name: limit_name.humanize(capitalize: false), count: limits.public_send(limit_name) } # rubocop:disable GitlabSecurity/PublicSend
    )
  end
end
