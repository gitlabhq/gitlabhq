module Projects
  class CreateService < BaseService
    attr_accessor :namespace_id

    def initialize(user, params)
      @current_user, @params = user, params.dup
      @namespace_id = @params.delete(:namespace_id)

      validate_visibility_level

      @project = Project.new(default_options.merge(@params))
    end

    def execute
      assign_namespace(namespace_id)
      project.creator = current_user

      begin
        if project.save
          add_user_as_master unless project.group

          project.update_column(:last_activity_at, project.created_at)

          import_repository
          create_wiki
        end
      rescue => ex
        project.errors.add(:base, "Can't save project. Please try again later")
      end

      project
    end

    private

    # Checks if the current user is allowed to assign the project's visibility level
    #
    # If not, delete the provided value from params
    def validate_visibility_level
      unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        params.delete(:visibility_level)
      end
    end

    def default_options
      features = Gitlab.config.gitlab.default_projects_features

      {
        issues_enabled: features.issues,
        wiki_enabled: features.wiki,
        wall_enabled: features.wall,
        snippets_enabled: features.snippets,
        merge_requests_enabled: features.merge_requests,
        visibility_level: features.visibility_level
      }.stringify_keys
    end

    def add_user_as_master
      project.users_projects.create(project_access: UsersProject::MASTER, user: current_user)
    end

    def import_repository
      if project.importable?
        project.import_start
      else
        GitlabShellWorker.perform_async(:add_repository, project.path_with_namespace)
      end
    end

    def create_wiki
      return unless project.wiki_enabled?

      GollumWiki.new(project, project.owner).wiki
    rescue GollumWiki::CouldNotCreateWikiError
      # Don't bubble up to ProjectObserver
    end

    # Assign a namespace to the project being created
    #
    # If a namespace is provided, we check to make sure the current user is
    # allowed to manage it, adding an error on :namespace if not.
    #
    # If no namespace is provided, the user's own namespace is used.
    def assign_namespace(id)
      if id
        # Lookup namespace and ensure current user is allowed to modify it
        namespace = Namespace.find(id)

        if current_user.can?(:manage_namespace, namespace)
          project.namespace = namespace
        else
          project.errors.add(:namespace, "is not valid")
        end
      else
        # Default to the current user's namespace
        project.namespace = current_user.namespace
      end
    end
  end
end
