# frozen_string_literal: true

module Organizations
  # SameOrganizationValidator
  #
  # An organization is isolated to a single cell, so two resource-parent-scoped
  # records (issues, work items, epics) in different organizations cannot
  # reference each other. This validates that the two associations named by
  # `left`/`right` (defaulting to `source`/`target`) belong to the same
  # organization.
  #
  # The check is gated by the `prevent_cross_organization_work_item_actions`
  # feature flag to control rollout.
  #
  # Usage:
  #   validates_with Organizations::SameOrganizationValidator
  #   validates_with Organizations::SameOrganizationValidator, left: :epic, right: :issue
  class SameOrganizationValidator < ActiveModel::Validator
    def validate(record)
      # rubocop:disable GitlabSecurity/PublicSend -- known symbols from options
      left = record.public_send(options.fetch(:left, :source))
      right = record.public_send(options.fetch(:right, :target))
      # rubocop:enable GitlabSecurity/PublicSend

      return unless left && right
      return unless Feature.enabled?(:prevent_cross_organization_work_item_actions, left.root_ancestor)
      return if left.same_organization_as?(right)

      record.errors.add(options.fetch(:right, :target), options[:message] || _('must belong to the same organization.'))
    end
  end
end
