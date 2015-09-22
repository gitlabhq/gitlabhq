module Ci
  class CreateProjectService
    include Gitlab::Application.routes.url_helpers

    def execute(current_user, params, forked_project = nil)
      @project = Ci::Project.parse(params)

      Ci::Project.transaction do
        @project.save!

        gl_project = ::Project.find(@project.gitlab_id)
        gl_project.build_missing_services
        gl_project.gitlab_ci_service.update_attributes(active: true, token: @project.token)
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
