# frozen_string_literal: true

# Acts as a pass-through to allow embeddable dashboards to be
# generated based on external data, but still processed with the
# required attributes that allow the FE to render them appropriately.
#
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class TransientEmbedService < ::Metrics::Dashboard::BaseEmbedService
      extend ::Gitlab::Utils::Override

      class << self
        def valid_params?(params)
          [
            embedded?(params[:embedded]),
            params[:embed_json]
          ].all?
        end
      end

      private

      override :get_raw_dashboard
      def get_raw_dashboard
        Gitlab::Json.parse(params[:embed_json])
      rescue JSON::ParserError => e
        invalid_embed_json!(e.message)
      end

      override :sequence
      def sequence
        [STAGES::MetricEndpointInserter]
      end

      override :identifiers
      def identifiers
        Digest::SHA256.hexdigest(params[:embed_json])
      end

      def invalid_embed_json!(message)
        raise DashboardProcessingError, _("Parsing error for param :embed_json. %{message}") % { message: message }
      end
    end
  end
end
