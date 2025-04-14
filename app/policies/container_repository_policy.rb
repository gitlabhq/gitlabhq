# frozen_string_literal: true

class ContainerRepositoryPolicy < BasePolicy
  delegate { @subject.project }

  condition(:protected_for_delete) { @subject.has_protected_tag_rules_for_delete?(@user) }

  rule { protected_for_delete }.policy do
    prevent :destroy_container_image
  end
end
