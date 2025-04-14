# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class TagRulePolicy < BasePolicy
      delegate { @subject.project }

      condition(:cannot_be_deleted_by_user) { !@subject.can_be_deleted?(@user) }

      rule { cannot_be_deleted_by_user }.policy do
        prevent :destroy_container_registry_protection_tag_rule
      end
    end
  end
end
