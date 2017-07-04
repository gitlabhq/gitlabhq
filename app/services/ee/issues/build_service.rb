module EE
  module Issues
    module BuildService
      def issue_params_from_template
        return {} unless project.feature_available?(:issuable_default_templates)

        { description: project.issues_template }
      end

      # Issue params can be built from 3 types of passed params,
      # They take precedence over eachother like this
      # passed params > discussion params > template params
      # The template params are filled in here, and might be overwritten by super
      def issue_params
        @issue_params ||= issue_params_from_template.merge(super)
      end
    end
  end
end
