# frozen_string_literal: true
module ContainerRegistry
  class TagPolicy < BasePolicy
    delegate { @subject.repository }

    condition(:protected_for_delete) { @subject.protected_for_delete?(@user) }

    rule { protected_for_delete }.policy do
      prevent :destroy_container_image
    end
  end
end
