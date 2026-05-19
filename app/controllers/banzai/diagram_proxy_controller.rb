# frozen_string_literal: true

module Banzai
  # Makes a downstream request to a diagram service (via Workhorse)
  # when the diagram has been intercepted by Banzai::Filter::DiagramProxyPostFilter.
  #
  # See:
  # * Banzai::Filter::KrokiFilter              (cached)
  # * Banzai::Filter::PlantumlFilter           (cached)
  # * Banzai::Filter::DiagramProxyPostFilter   (run during post-process, on every request)
  class DiagramProxyController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :enforce_terms!
    skip_before_action :check_two_factor_requirement

    feature_category :markdown

    def proxy
      return not_found unless request_data
      return not_found if request_user_id != current_user&.id

      url =
        if request_diagram_type == 'plantuml'
          return not_found unless Gitlab::CurrentSettings.plantuml_diagram_proxy_enabled?

          ::Banzai::Filter::PlantumlFilter.plantuml_img_src(request_diagram_source)
        else
          return not_found unless Gitlab::CurrentSettings.kroki_diagram_proxy_enabled?

          ::Banzai::Filter::KrokiFilter.kroki_image_src(request_diagram_type, request_diagram_source)
        end

      headers.store(*Gitlab::Workhorse.send_url(
        url,
        allow_redirects: true,
        ssrf_filter: true,
        # rubocop:disable Naming/InclusiveLanguage -- existing setting
        allowed_endpoints: Gitlab::CurrentSettings.outbound_local_requests_whitelist
        # rubocop:enable Naming/InclusiveLanguage
      ))
      head :ok
    end

    private

    def request_user_id
      request_data[:user_id]
    end

    def request_diagram_type
      request_data[:diagram_type]
    end

    def request_diagram_source
      request_data[:diagram_source]
    end

    def request_data
      return unless key

      # We can only fetch this once.
      raw_data = ::Banzai::Filter::DiagramProxyPostFilter.getdel(key)
      return unless raw_data

      # If there's data there, it should always be valid, as we stored it originally
      # in DiagramProxyPostFilter.
      # Raising if it's invalid/unexpectedly nil/etc. is the correct behaviour.
      Gitlab::Json.safe_parse(raw_data).symbolize_keys
    end
    strong_memoize_attr :request_data

    def key
      params.permit(:key)[:key]
    end
  end
end
