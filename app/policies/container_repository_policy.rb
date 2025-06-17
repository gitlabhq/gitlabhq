# frozen_string_literal: true

class ContainerRepositoryPolicy < BasePolicy
  delegate { @subject.project }

  condition(:protected_for_delete) { @subject.protected_from_delete_by_tag_rules?(@user) }

  rule { protected_for_delete }.policy do
    prevent :destroy_container_image
  end
end
