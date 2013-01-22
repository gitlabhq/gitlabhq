module Projects
  class CreateContext < BaseContext
    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      # get namespace id
      namespace_id = params.delete(:namespace_id)

      @project = Project.new(params)

      # Parametrize path for project
      #
      # Ex.
      #  'GitLab HQ'.parameterize => "gitlab-hq"
      #
      if Gitlab.config.gitlab.case_sensitive
       parameterized_string = ActiveSupport::Inflector.transliterate(@project.name)
       parameterized_string.gsub!(/[^a-z0-9\-_]+/i, '-')
       re_sep = Regexp.escape('-')
       parameterized_string.gsub!(/#{re_sep}{2,}/, '-')
       parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/i, '')
       @project.path = parameterized_string
      else
       @project.path = @project.name.dup.parameterize
      end


      if namespace_id
        # Find matching namespace and check if it allowed
        # for current user if namespace_id passed.
        if allowed_namespace?(current_user, namespace_id)
          @project.namespace_id = namespace_id unless namespace_id == Namespace.global_id
        else
          deny_namespace
          return @project
        end
      else
        # Set current user namespace if namespace_id is nil
        @project.namespace_id = current_user.namespace_id
      end

      Project.transaction do
        @project.creator = current_user
        @project.save!

        # Add user as project master
        @project.users_projects.create!(project_access: UsersProject::MASTER, user: current_user)

        # when project saved no team member exist so
        # project repository should be updated after first user add
        @project.update_repository
      end

      @project
    rescue => ex
      @project.errors.add(:base, "Can't save project. Please try again later")
      @project
    end

    protected

    def deny_namespace
      @project.errors.add(:namespace, "is not valid")
    end

    def allowed_namespace?(user, namespace_id)
      if namespace_id == Namespace.global_id
        return user.admin
      else
        namespace = Namespace.find_by_id(namespace_id)
        current_user.can?(:manage_namespace, namespace)
      end
    end
  end
end
