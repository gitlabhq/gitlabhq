module EE
  module Projects
    module PipelinesController
      extend ActiveSupport::Concern

      def security
        commit

        if pipeline.expose_sast_data?
          render_show
        else
          redirect_to pipeline_path(pipeline)
        end
      end
    end
  end
end
