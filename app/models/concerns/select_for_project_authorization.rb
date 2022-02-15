# frozen_string_literal: true

module SelectForProjectAuthorization
  extend ActiveSupport::Concern

  class_methods do
    def select_for_project_authorization
      select("projects.id AS project_id", "members.access_level")
    end

    # workaround until we migrate Project#owners to have membership with
    # OWNER access level
    def select_project_owner_for_project_authorization
      if ::Feature.enabled?(:personal_project_owner_with_owner_access, default_enabled: :yaml)
        select(["projects.id AS project_id", "#{Gitlab::Access::OWNER} AS access_level"])
      else
        select(["projects.id AS project_id", "#{Gitlab::Access::MAINTAINER} AS access_level"])
      end
    end
  end
end
