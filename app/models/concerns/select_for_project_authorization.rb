module SelectForProjectAuthorization
  extend ActiveSupport::Concern

  module ClassMethods
    def select_for_project_authorization
      select("members.user_id, projects.id AS project_id, members.access_level")
    end
  end
end
