module Ci
  class CreateProjectService
    include Gitlab::Application.routes.url_helpers

    def execute(current_user, params, project_route, forked_project = nil)
      @project = Ci::Project.parse(params)

      Ci::Project.transaction do
        @project.save!

        data = {
          token: @project.token,
          project_url: project_route.gsub(":project_id", @project.id.to_s),
        }

        unless Ci::Network.new.enable_ci(@project.gitlab_id, data, current_user.authenticate_options)
          raise ActiveRecord::Rollback
        end
      end

      if forked_project
        # Copy settings
        settings = forked_project.attributes.select do |attr_name, value|
          ["public", "shared_runners_enabled", "allow_git_fetch"].include? attr_name
        end

        @project.update(settings)
      end

      Ci::EventService.new.create_project(current_user, @project)

      @project
    end
  end
end
