# frozen_string_literal: true

module Banzai
  module Pipeline
    class ServiceDeskEmailPipeline < EmailPipeline
      def self.filters
        super.insert_before(Filter::ExternalLinkFilter, Banzai::Filter::ServiceDeskUploadLinkFilter)
      end

      def self.transform_context(context)
        super.merge(for_service_desk_email: true)
      end
    end
  end
end
