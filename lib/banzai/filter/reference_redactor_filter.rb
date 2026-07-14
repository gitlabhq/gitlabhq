# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that removes references to records that the current user does
    # not have permission to view.
    #
    # Expected to be run in its own post-processing pipeline.
    #
    class ReferenceRedactorFilter < HTML::Pipeline::Filter
      include Concerns::ContextAccessors

      def call
        unless context[:skip_redaction]
          redactor_context = RenderContext.new(project, current_user)

          ReferenceRedactor.new(redactor_context).redact([doc])
        end

        doc
      end
    end
  end
end
