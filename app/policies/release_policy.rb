# frozen_string_literal: true

class ReleasePolicy < BasePolicy
  delegate { @subject.project }

  condition(:protected_tag) do
    access = ::Gitlab::UserAccess.new(@user, container: @subject.project)

    !access.can_create_tag?(@subject.tag)
  end

  rule { protected_tag }.policy do
    prevent :create_release
    prevent :update_release
    prevent :destroy_release
    prevent :publish_catalog_version
  end
end
