# frozen_string_literal: true

module MilestonesHelper
  def milestone_issuable_group(issuable)
    (issuable.respond_to?(:namespace) && issuable.namespace.is_a?(Group) ? issuable.namespace : nil)
  end
end
