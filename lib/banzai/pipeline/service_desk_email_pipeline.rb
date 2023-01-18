# frozen_string_literal: true

module Banzai
  module Pipeline
    class ServiceDeskEmailPipeline < EmailPipeline
      def self.filters
        super.insert_before(Filter::ExternalLinkFilter, Banzai::Filter::ServiceDeskUploadLinkFilter)
      end
    end
  end
end
