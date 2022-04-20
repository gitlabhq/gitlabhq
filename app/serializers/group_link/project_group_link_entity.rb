# frozen_string_literal: true

module GroupLink
  class ProjectGroupLinkEntity < GroupLink::GroupLinkEntity
    include RequestAwareEntity

    expose :source do |group_link|
      ProjectEntity.represent(group_link.shared_from, only: [:id, :full_name])
    end

    private

    def admin_permission_name
      :admin_project_member
    end
  end
end
