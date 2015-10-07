module Ci
  class EventService
    def remove_project(user, project)
      create(
        description: "Project \"#{project.name}\" has been removed by #{user.username}",
        user_id: user.id,
        is_admin: true
      )
    end

    def create_project(user, project)
      create(
        description: "Project \"#{project.name}\" has been created by #{user.username}",
        user_id: user.id,
        is_admin: true
      )
    end

    def change_project_settings(user, project)
      create(
        project_id: project.id,
        user_id: user.id,
        description: "User \"#{user.username}\" updated projects settings"
      )
    end

    def create(*args)
      Ci::Event.create!(*args)
    end
  end
end
