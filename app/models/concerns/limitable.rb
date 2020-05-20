# frozen_string_literal: true

module Limitable
  extend ActiveSupport::Concern

  included do
    class_attribute :limit_scope
    class_attribute :limit_name
    self.limit_name = self.name.demodulize.tableize

    validate :validate_plan_limit_not_exceeded, on: :create
  end

  private

  def validate_plan_limit_not_exceeded
    scope_relation = self.public_send(limit_scope) # rubocop:disable GitlabSecurity/PublicSend
    return unless scope_relation

    relation = self.class.where(limit_scope => scope_relation)

    if scope_relation.actual_limits.exceeded?(limit_name, relation)
      errors.add(:base, _("Maximum number of %{name} (%{count}) exceeded") %
        { name: limit_name.humanize(capitalize: false), count: scope_relation.actual_limits.public_send(limit_name) }) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
