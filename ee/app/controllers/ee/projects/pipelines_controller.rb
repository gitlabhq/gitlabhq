module EE
  module Projects
    module PipelinesController
      extend ActiveSupport::Concern

      def security
        if pipeline.expose_security_dashboard?
          render_show
        else
          redirect_to pipeline_path(pipeline)
        end
      end

      def licenses
        if pipeline.expose_license_management_data?
          render_show
        else
          redirect_to pipeline_path(pipeline)
        end
      end
    end
  end
end
