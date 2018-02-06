module SelectForProjectAuthorization
  extend ActiveSupport::Concern

  module ClassMethods
    def select_for_project_authorization
      select("projects.id AS project_id, members.access_level")
    end

    def select_as_master_for_project_authorization
      select(["projects.id AS project_id", "#{Gitlab::Access::MASTER} AS access_level"])
    end
  end
end
