module Banzai
  module Filter
    # HTML filter that removes references to records that the current user does
    # not have permission to view.
    #
    # Expected to be run in its own post-processing pipeline.
    #
    class RedactorFilter < HTML::Pipeline::Filter
      def call
        unless context[:skip_redaction]
          context = RenderContext.new(project, current_user)

          Redactor.new(context).redact([doc])
        end

        doc
      end

      private

      def current_user
        context[:current_user]
      end

      def project
        context[:project]
      end
    end
  end
end
