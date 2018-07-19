module EE
  module Clusters
    module Applications
      module BaseHelmService
        protected

        def upgrade_command(new_values = "")
          @upgrade_command ||= app.upgrade_command(new_values)
        end
      end
    end
  end
end
