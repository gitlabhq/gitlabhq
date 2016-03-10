module Projects
  module ImportExport
    module ProjectFactory
      extend self

      def create(project_params:, user:, members:)
        project = Project.new(project_params.except('id'))
        project.creator = user
        check_namespace(project_params['namespace_id'], project, user)
      end

      def check_namespace(namespace_id, project, user)
        if namespace_id
          # Find matching namespace and check if it allowed
          # for current user if namespace_id passed.
          unless allowed_namespace?(user, namespace_id)
            project.namespace_id = nil
            deny_namespace(project)
          end
        else
          # Set current user namespace if namespace_id is nil
          project.namespace_id = user.namespace_id
        end
        project
      end

      private

      def allowed_namespace?(user, namespace_id)
        namespace = Namespace.find_by(id: namespace_id)
        user.can?(:create_projects, namespace)
      end

      def deny_namespace(project)
        project.errors.add(:namespace, "is not valid")
      end

    end
  end
end
