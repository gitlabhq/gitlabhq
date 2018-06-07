# Gitlab::Access module
#
# Define allowed roles that can be used
# in GitLab code to determine authorization level
#
module EE
  module Gitlab
    module Access
      extend self

      # Default project creation level
      NO_ONE_PROJECT_ACCESS = 0
      MASTER_PROJECT_ACCESS = 1
      DEVELOPER_MASTER_PROJECT_ACCESS = 2

      def project_creation_options
        {
          s_('ProjectCreationLevel|No one') => NO_ONE_PROJECT_ACCESS,
          s_('ProjectCreationLevel|Maintainers') => MASTER_PROJECT_ACCESS,
          s_('ProjectCreationLevel|Developers + Maintainers') => DEVELOPER_MASTER_PROJECT_ACCESS
        }
      end
    end
  end
end
