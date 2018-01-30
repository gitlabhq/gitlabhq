module EE
  module Projects
    module JobsController
      extend ActiveSupport::Concern
      include SendFileUpload

      def raw
        if trace_artifact_file
          send_upload(trace_artifact_file,
                      send_params: raw_send_params,
                      redirect_params: raw_redirect_params)
        else
          super
        end
      end

      private

      def raw_send_params
        { type: 'text/plain; charset=utf-8', disposition: 'inline' }
      end

      def raw_redirect_params
        { query: { "response-content-disposition" => "attachment;filename=#{trace_artifact_file.filename}" } }
      end

      def trace_artifact_file
        @trace_artifact_file ||= build.job_artifacts_trace&.file
      end
    end
  end
end
